extends PlayerController
class_name HumanPlayerController

enum State { IDLE, 
			TARGETING_0, # no click on targeting
			TARGETING_1, # one click on targeting still previewing
			TARGETING_2  # second click on targeting
		}

signal clicked_hex(hex_qr: Vector2i)

var input_manager_: InputManager
var tactical_overlay_: TacticalOverlay
var hud_: HUD
var current_state_: State = State.IDLE
var current_viable_hexes_: Array[Vector2i]
var current_context: ActionContext = null
var current_selected_hex_ = null
var current_selected_unit_: UnitData = null
var current_effect_: Effect = null
var current_playing_: bool = false

func _ready() -> void:
	SignalBus.end_turn.connect(_on_end_turn)
	SignalBus.unit_action_selected.connect(_on_unit_action_selected)
	SignalBus.start_turn.connect(_on_start_turn)
	SignalBus.debug_player_reaction.connect(_on_start_turn)
	input_manager_.tactical_input.connect(_on_tactical_input)
	pass # Replace with function body.

func _on_end_turn() -> void:
	if current_selected_unit_ and current_playing_:
		current_selected_unit_.deselect()
		current_selected_unit_ = null

func _on_start_turn(player_number: int, peer_id: int) -> void:
	if player_number != player_id_:
		current_playing_ = false
	else:
		current_playing_ = true

func _init(level : Node, peer_id: int, input_manager: InputManager, tac_overlay: TacticalOverlay, hud: HUD) -> void:
	super._init(level, peer_id)
	input_manager_ = input_manager
	tactical_overlay_ = tac_overlay
	hud_ = hud
	

func _on_unit_action_selected(unit: UnitData, ability: Ability, sub_name: String) -> void:
	if not current_playing_:
		return
	if game_board_.is_ability_executable(unit, ability):
		execute_ability(ability, unit, sub_name)
	else:
		var visual_unit: Unit = VisualManager.visual_registry.get_mapping(unit)
		VFXManager.spawn_text({"text_to_show" : "not enough action points", "global_position" : visual_unit.global_position})

func handle_select_unit(target_unit: UnitData) -> void:
	if not current_playing_:
		return
	if current_selected_unit_ != null:
		current_selected_unit_.deselect()
		SignalBus.unit_deselected.emit(current_selected_unit_)
	target_unit.select()
	SignalBus.unit_selected.emit(target_unit)	
	current_selected_unit_ = target_unit

func draw_preview(context: ActionContext, target_qr: Vector2i, effect: Effect):
	if not current_playing_:
		return
	if context.ability_.action_type_ == Ability.ActionType.MOVEMENT:
		tactical_overlay_.clear_breadcrumbs()
		var move_path = context.game_board_.get_move_path(context.source_unit_, context.source_unit_.get_pos_qr(), target_qr)
		tactical_overlay_.draw_breadcrumbs(move_path)

func clear_preview(context: ActionContext, effect: Effect):
	if not current_playing_:
		return
	if context.ability_.action_type_ == Ability.ActionType.MOVEMENT:
		tactical_overlay_.clear_breadcrumbs()

# --- THE EXECUTION COROUTINE ---
func get_picked_hexes(context: ActionContext, viable_hexes: Array[Vector2i], effect: Effect) -> Vector2i:
	#if not current_playing_:
	#	return Vector2i(-1, -1)
	current_viable_hexes_ = viable_hexes
	current_context = context
	current_state_ = State.TARGETING_0
	current_effect_ = effect
	tactical_overlay_.draw_highlights(viable_hexes, Color.FIREBRICK, TacticalOverlay.CursorGroup.PREVIEW)
	
	# 2. Yield until the state machine emits this signal
	while true:
		var target = await self.clicked_hex
		match current_state_:
			State.TARGETING_0:
				clear_preview(context, effect)
			State.TARGETING_1:
				draw_preview(context, target, effect)
			State.TARGETING_2:
				# 3. Cleanup and return
				tactical_overlay_.clear_preview()
				current_viable_hexes_ = []
				current_context = null
				current_state_ = State.IDLE
				return target
			State.IDLE:
				Utils.log_error("player controller state machine reached IDLE state during pick phase")
				break
	return Vector2i(-1,-1)

func handle_hover(hovered_hex_qr) -> void:
	if not current_playing_:
		return
	var active_draw : Array[Vector2i] = []
	if hovered_hex_qr != Vector2i(-9999, -9999):
		if current_state_ == State.TARGETING_1 or current_state_ == State.TARGETING_2 or current_state_ == State.TARGETING_0:
			active_draw.append_array(game_board_.get_affected_hexes(hovered_hex_qr, current_effect_, current_context.source_unit_.get_pos_qr()))
		else:
			active_draw.append(hovered_hex_qr)
	tactical_overlay_.draw_highlights(active_draw, Color.WHITE, TacticalOverlay.CursorGroup.ACTIVE)
		
	
# --- THE STATE MACHINE ---
func _on_tactical_input(action: InputManager.Action, hex: Vector2i) -> void:
	#if not current_playing_:
	#	return
	match action:
		InputManager.Action.HOVER:
			handle_hover(hex)
			
		InputManager.Action.CLICK:
			handle_click(hex)
			
		InputManager.Action.CANCEL:
			if current_state_ != State.IDLE:
				current_state_ = State.IDLE
				clicked_hex.emit(null) # Emitting null cleanly aborts the ability

func handle_click(hex: Vector2i) -> void:
	match current_state_:
		State.IDLE:
			# Normal gameplay clicks (selecting units, checking stats, etc.)
			var hex_data: GameBoard.HexData = game_board_.get_hex_data(hex)
			if hex_data.unit != null:
				handle_select_unit(hex_data.unit)
				
		State.TARGETING_0:
			# First click: Lock in the target for preview
			if hex in current_viable_hexes_:
				current_selected_hex_ = hex
				current_state_ = State.TARGETING_1
				clicked_hex.emit(hex)
				
		State.TARGETING_1:
			# Second click: Confirm or cancel
			if hex == current_selected_hex_:
				# Confirmed! Fire the signal to resume `get_picked_hexes`
				current_state_ = State.TARGETING_2
				clicked_hex.emit(hex) 
			elif hex in current_viable_hexes_:
				# They clicked a different viable hex. Switch the locked preview.
				current_selected_hex_ = hex
				clicked_hex.emit(hex)
			else:
				# They clicked an invalid hex. Downgrade back to TARGETING_0.
				current_selected_hex_ = null
				current_state_ = State.TARGETING_0
				clicked_hex.emit(null)

func user_choose_reaction(reaction_msg: String, valid_reactions_string: Array[String]):
	return await hud_.show_reaction_menu(reaction_msg, valid_reactions_string)

func choose_reaction(src_ability: Ability, reaction_params: Dictionary, reacting_unit: UnitData, valid_reactions: Array[ReactionManager.Reaction]):
	var reaction_strings: Array[String] = []
	for rxn in valid_reactions:
		reaction_strings.append(rxn.ability.get_ui_name())
	var message = "please select a reaction"
	var reaction_id = await user_choose_reaction(message, reaction_strings)
	return valid_reactions[reaction_id]
				
