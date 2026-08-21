# InputManager.gd
extends Node
class_name InputManager

enum State {
	IDLE,
	MOVE_SELECT_TARGET,
	MOVE_CONFIRM_TARGET,
	ATTACK_SELECT_TARGET,
	ATTACK_CONFIRM_TARGET,
}

enum Action { CLICK, HOVER, CANCEL }

signal tactical_input(action: Action, hex: Vector2i)

# ... inside your _unhandled_input or similar:
# emit_signal("tactical_input", Action.CLICK, current_hex)
# emit_signal("tactical_input", Action.CANCEL, Vector2i.ZERO)

@export var game_board_: GameBoard
@export var tactical_overlay_: TacticalOverlay


var current_hovered_hex: Vector2i = Vector2i(-9999, -9999)
var current_state_: State = State.IDLE
var current_acting_unit_: Unit = null
var current_selected_unit_: UnitData = null
var last_clicked_hex_: Vector2i = Vector2i(-9999, -9999)
var preview_move_path_: Array[Vector2i] = []
var current_viable_hexes_: Array[Vector2i] = []

#debug stuff
var debug_sphere: MeshInstance3D

func _ready() -> void:
	create_debug_sphere()
	SignalBus.unit_move_button_pressed.connect(_on_move_button_pressed)
	pass

func _on_move_button_pressed(selected_unit: Unit):
	current_state_ = State.MOVE_SELECT_TARGET
	current_acting_unit_ = selected_unit

func handle_move(target_hex: Vector2i) -> void:
	var unit_world_pos: Vector3 = current_acting_unit_.get_position_in_world()
	var unit_axial_pos: Vector2i = HexUtils.world_to_axial(unit_world_pos)
	preview_move_path_ = game_board_.get_unit_move_path(current_acting_unit_, target_hex)
	if not preview_move_path_.is_empty():
		tactical_overlay_.draw_breadcrumbs(preview_move_path_)
		current_state_ = State.MOVE_CONFIRM_TARGET
		
func handle_attack(target_unit: Unit) -> void:
	current_state_ = State.ATTACK_CONFIRM_TARGET

func handle_select_unit(target_unit: UnitData) -> void:
	if current_selected_unit_ != null:
		current_selected_unit_.deselect()
	target_unit.unit_.select()
	SignalBus.unit_selected.emit(target_unit.unit_)	
	current_selected_unit_ = target_unit
	
func is_state_conforming() -> bool:
	match current_state_:
		State.MOVE_CONFIRM_TARGET:
			return true
		State.ATTACK_CONFIRM_TARGET:
			return true
	return false

func handle_hex_clicked(clicked_hex: Vector2i) -> void:
	var hex_data: GameBoard.HexData = game_board_.get_hex_data(clicked_hex)
	match current_state_:
		State.MOVE_CONFIRM_TARGET:
			if last_clicked_hex_ == clicked_hex:
				tactical_overlay_.clear_breadcrumbs()
				game_board_.move_unit(current_acting_unit_, preview_move_path_, 1)
				current_state_ = State.MOVE_SELECT_TARGET
		State.ATTACK_CONFIRM_TARGET:
			if last_clicked_hex_ == clicked_hex:
				game_board_.attack(current_acting_unit_, last_clicked_hex_)
		State.MOVE_SELECT_TARGET:
			if hex_data.unit != null:
				handle_select_unit(hex_data.unit)
			else:
				handle_move(clicked_hex)
		State.ATTACK_SELECT_TARGET:
			if hex_data.unit != null:
				pass
				#handle_attack(hex_data.unit)
		State.IDLE:
			if hex_data.unit != null:
				handle_select_unit(hex_data.unit)
	last_clicked_hex_ = clicked_hex

# viable hexes in axial coordiantes
func pick_hexes(viable_hexes: Array[Vector2i]) -> Variant:
	current_state_ = State.MOVE_SELECT_TARGET
	current_viable_hexes_ = viable_hexes
	var result = await self.hex_picked
	
	current_state_ = State.IDLE
	current_viable_hexes_ = []
	return result

func _process(_delta: float) -> void:
	var hovered_hex = _raycast_mouse_to_hex()
	
	# Only emit when crossing hex boundaries (prevents spam)
	if hovered_hex != current_hovered_hex:
		current_hovered_hex = hovered_hex
		#SignalBus.ui_hex_hovered.emit(current_hovered_hex)
		tactical_input.emit(Action.HOVER, current_hovered_hex)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if current_hovered_hex != Vector2i(-9999, -9999):
			get_viewport().set_input_as_handled() # Prevents click leakage
			#handle_hex_clicked(current_hovered_hex)
			tactical_input.emit(Action.CLICK, current_hovered_hex)
			
func _raycast_mouse_to_hex() -> Vector2i:
	# Dynamically grab the active 3D camera from the current viewport
	var camera = get_viewport().get_camera_3d()
	
	# Guard clause: If no camera exists (e.g., headless server, camera destroyed), fail safely
	if not camera:
		return Vector2i(-9999, -9999)
		
	var mouse_pos = get_viewport().get_mouse_position()
	var ray_origin = camera.project_ray_origin(mouse_pos)
	var ray_end = ray_origin + camera.project_ray_normal(mouse_pos) * 1000.0
	
	var space_state = camera.get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
	query.collide_with_bodies = true
	
	var result = space_state.intersect_ray(query)
	if result: 
		debug_sphere.global_position = result.position
	if result and result.collider is StaticBody3D:
		var local_hit = result.collider.to_local(result.position)
		return HexUtils.world_to_axial(local_hit)
	return Vector2i(-9999, -9999)

func create_debug_sphere() -> void:
	debug_sphere = MeshInstance3D.new()
	var sphere_mesh = SphereMesh.new()
	sphere_mesh.radius = 0.2
	sphere_mesh.height = 0.4
	debug_sphere.mesh = sphere_mesh
	
	# 2. Create a bright red material
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color.RED
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED # Makes it glow without lights
	mat.no_depth_test = true # Forces it to draw ON TOP of the ground, never inside it
	debug_sphere.material_override = mat
	
	# 3. Add it to the world
	add_child(debug_sphere)
	debug_sphere.set_as_top_level(true) # Detaches its transform from the parent
