extends Node3D

@export var camera_pivot: CameraPivot
@export var hex_cursor: Node3D

# Tracks the hex currently under the mouse to prevent redundant animations
var current_hovered_hex: Vector2i = Vector2i(-9999, -9999) 
var cursor_tween: Tween

# Called every frame. 'delta' is the elapsed time since the previous frame.
# Store where the cursor *wants* to be
var target_position: Vector3
var is_cursor_active: bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


func _process(delta: float) -> void:
	var camera = camera_pivot.get_camera()
	var mouse_pos = get_viewport().get_mouse_position()
	var ray_origin = camera_pivot.get_camera().project_ray_origin(mouse_pos)
	var ray_end = ray_origin + camera.project_ray_normal(mouse_pos) * 1000.0
	
	# It is perfectly safe to query the physics state in _process for mouse picking
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
	query.collide_with_bodies = true
	
	var result = space_state.intersect_ray(query)
	
	if result and result.collider is StaticBody3D:
		var hit_position = result.position
		var terrain_body = result.collider
		
		# 1. Convert the global raycast hit into the terrain's local coordinate space
		var local_hit_pos = terrain_body.to_local(hit_position)
		
		# 2. Calculate the hex coordinate based on the local space
		var hovered_hex = HexUtils.world_to_axial(local_hit_pos)
		
		# 3. Find where the center of that hex is in local space
		var local_target_pos = HexUtils.axial_to_world(hovered_hex)
		
		# 4. Convert that local center back into global space for the cursor
		target_position = terrain_body.to_global(local_target_pos)
		target_position.y = hit_position.y + 0.05
		
		# If this is the first time the cursor appears, snap it instantly so it doesn't fly in from nowhere
		if not is_cursor_active:
			hex_cursor.global_position = target_position
			hex_cursor.visible = true
			is_cursor_active = true
	else:
		# Hide cursor if mouse goes off the map
		is_cursor_active = false
		if hex_cursor:
			hex_cursor.visible = false
			
	# 2. Smoothly move the cursor towards the target EVERY frame
	if is_cursor_active and hex_cursor:
		# The multiplier (25.0) controls the speed. 
		# Higher = tighter/snappier, Lower = looser/more floaty
		var smooth_speed = 75.0 * delta
		hex_cursor.global_position = target_position #hex_cursor.global_position.lerp(target_position, smooth_speed)
