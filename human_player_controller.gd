extends PlayerController
class_name HumanPlayerController

enum State { IDLE, TARGETING_1, TARGETING_2 }

signal picked_hex(hex)

var input_manager_: InputManager
var tactical_overlay_: TacticalOverlay
var current_state_: State = State.IDLE
var current_viable_hexes_: Array[Vector2i]
var current_context: ActionContext = null
var current_selected_hex_ = null
var current_selected_unit_: Unit = null

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

func _on_unit_action_selected(unit: UnitData, ability: Ability) -> void:
	execute_ability(ability, unit)

func handle_select_unit(target_unit: UnitData) -> void:
	if current_selected_unit_ != null:
		current_selected_unit_.deselect()
	target_unit.unit_.select()
	SignalBus.unit_selected.emit(target_unit.unit_)	
	current_selected_unit_ = target_unit.unit_

# --- THE EXECUTION COROUTINE ---
func get_picked_hexes(context: ActionContext, viable_hexes: Array[Vector2i]) -> Array[Vector2i]:
	current_viable_hexes_ = viable_hexes
	current_context = context
	current_state_ = State.TARGETING_1
	
	var draw_hexes: Array[Vector3] = []
	for x in viable_hexes:
		var local_pos: Vector3 = context.game_board_.convert_hex_to_terrain_coords(x)
		draw_hexes.append(local_pos)
	tactical_overlay_._on_draw_highlights(draw_hexes)
	
	# 2. Yield until the state machine emits this signal
	var target = await self.picked_hex
	
	# 3. Cleanup and return
	#tactical_overlay.clear()
	current_viable_hexes_ = []
	current_context = null
	return target
	
	
# --- THE STATE MACHINE ---
func _on_tactical_input(action: InputManager.Action, hex: Vector2i) -> void:
	match action:
		InputManager.Action.HOVER:
			if current_state_ == State.TARGETING_1 and hex in current_viable_hexes_:
				# Show what WOULD happen if they clicked here
				pass		
				#tactical_overlay.draw_hover_preview(_active_context.effect.get_preview(hex))
				
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
				#tactical_overlay.draw_locked_preview(_active_context.effect.get_preview(hex))
				
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
