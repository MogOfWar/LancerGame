# InputManager.gd
extends Node
class_name InputManager

enum Action { CLICK, HOVER, CANCEL }

signal tactical_input(action: Action, hex: Vector2i)


var current_hovered_hex: Vector2i = Vector2i(-9999, -9999)

#debug stuff
var debug_sphere: MeshInstance3D

func _ready() -> void:
	create_debug_sphere()
	pass

func _process(_delta: float) -> void:
	var hovered_hex = _raycast_mouse_to_hex()
	
	# Only emit when crossing hex boundaries (prevents spam)
	if hovered_hex != current_hovered_hex:
		current_hovered_hex = hovered_hex
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
		var qr = HexUtils.world_to_axial(local_hit)
		if Level.get_current_level().game_board_ and Level.get_current_level().game_board_.grid_:
			if not Level.get_current_level().game_board_.grid_.check_hex_in_grid(qr):
				return Vector2i(-9999, -9999)

		return qr
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
