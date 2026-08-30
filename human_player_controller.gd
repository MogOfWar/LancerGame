extends PlayerController
class_name HumanPlayerController

enum State { IDLE, TARGETING_1, TARGETING_2 }

signal picked_hex(hex_qr: Vector2i)
signal preview_hex(hex_qr: Vector2i)

var input_manager_: InputManager
var tactical_overlay_: TacticalOverlay
var current_state_: State = State.IDLE
var current_viable_hexes_: Array[Vector2i]
var current_context: ActionContext = null
var current_selected_hex_ = null
var current_selected_unit_: UnitData = null
var current_effect_: Effect = null

func _ready() -> void:
	SignalBus.unit_action_selected.connect(_on_unit_action_selected)
	input_manager_.tactical_input.connect(_on_tactical_input)
	pass # Replace with function body.

func _init(logic_node : Node, input_manager: InputManager, tac_overlay: TacticalOverlay) -> void:
	super._init(logic_node)
	input_manager_ = input_manager
	tactical_overlay_ = tac_overlay
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_unit_action_selected(unit: UnitData, ability: Ability, sub_name: String) -> void:
	if game_board_.is_ability_executable(unit, ability):
		execute_ability(ability, unit, sub_name)
	else:
		var visual_unit: Unit = VisualManager.visual_registry.get_mapping(unit)
		VFXManager.spawn_text({"text_to_show" : "not enough action points", "global_position" : visual_unit.global_position})

func handle_select_unit(target_unit: UnitData) -> void:
	if current_selected_unit_ != null:
		current_selected_unit_.deselect()
	target_unit.select()
	SignalBus.unit_selected.emit(target_unit)	
	current_selected_unit_ = target_unit

func draw_preview(context: ActionContext, target_qr: Vector2i, effect: Effect):
	if context.ability_.action_type_ == Ability.ActionType.MOVEMENT:
		tactical_overlay_.clear_breadcrumbs()
		var move_path = context.game_board_.get_move_path(context.source_unit_.get_pos_qr(), target_qr)
		tactical_overlay_.draw_breadcrumbs(move_path)

# --- THE EXECUTION COROUTINE ---
func get_picked_hexes(context: ActionContext, viable_hexes: Array[Vector2i], effect: Effect) -> Vector2i:
	current_viable_hexes_ = viable_hexes
	current_context = context
	current_state_ = State.TARGETING_1
	current_effect_ = effect
	tactical_overlay_.draw_highlights(viable_hexes, Color.FIREBRICK, TacticalOverlay.CursorGroup.PREVIEW)
	
	# 2. Yield until the state machine emits this signal
	var target = await self.preview_hex
	draw_preview(context, target, effect)
	
	var confiremed_hex = await self.picked_hex
	# 3. Cleanup and return
	tactical_overlay_.clear_preview()
	current_viable_hexes_ = []
	current_context = null
	return target

func handle_hover(hovered_hex_qr) -> void:
	var active_draw : Array[Vector2i] = []
	if hovered_hex_qr != Vector2i(-9999, -9999):
		if current_state_ == State.TARGETING_1 or current_state_ == State.TARGETING_2:
			active_draw.append_array(game_board_.get_affected_hexes(hovered_hex_qr, current_effect_, current_context.source_unit_.get_pos_qr()))
		else:
			active_draw.append(hovered_hex_qr)
	tactical_overlay_.draw_highlights(active_draw, Color.WHITE, TacticalOverlay.CursorGroup.ACTIVE)
		
	
# --- THE STATE MACHINE ---
func _on_tactical_input(action: InputManager.Action, hex: Vector2i) -> void:
	match action:
		InputManager.Action.HOVER:
			handle_hover(hex)
			
		InputManager.Action.CLICK:
			handle_click(hex)
			
		InputManager.Action.CANCEL:
			if current_state_ != State.IDLE:
				current_state_ = State.IDLE
				picked_hex.emit(null) # Emitting null cleanly aborts the ability

func handle_click(hex: Vector2i) -> void:
	match current_state_:
		State.IDLE:
			# Normal gameplay clicks (selecting units, checking stats, etc.)
			var hex_data: GameBoard.HexData = game_board_.get_hex_data(hex)
			if hex_data.unit != null:
				handle_select_unit(hex_data.unit)
				
		State.TARGETING_1:
			# First click: Lock in the target for preview
			if hex in current_viable_hexes_:
				current_selected_hex_ = hex
				current_state_ = State.TARGETING_2
				preview_hex.emit(hex)
				
		State.TARGETING_2:
			# Second click: Confirm or cancel
			if hex == current_selected_hex_:
				# Confirmed! Fire the signal to resume `get_picked_hexes`
				current_state_ = State.IDLE
				picked_hex.emit(hex) 
			elif hex in current_viable_hexes_:
				# They clicked a different viable hex. Switch the locked preview.
				current_selected_hex_ = hex
				#tactical_overlay.draw_locked_preview(_active_context.effect.get_preview(hex))
			else:
				# They clicked an invalid hex. Downgrade back to TARGETING_1.
				current_selected_hex_ = null
				current_state_ = State.TARGETING_1
				#tactical_overlay.clear_preview()
				#tactical_overlay.draw_viable(_active_viable_hexes)
