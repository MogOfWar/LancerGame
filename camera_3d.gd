extends Camera3D

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
	var mouse_pos = get_viewport().get_mouse_position()
	var ray_origin = project_ray_origin(mouse_pos)
	var ray_end = ray_origin + project_ray_normal(mouse_pos) * 1000.0
	
	# It is perfectly safe to query the physics state in _process for mouse picking
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
	query.collide_with_bodies = true
	
	var result = space_state.intersect_ray(query)
	
	if result and result.collider is StaticBody3D:
		var hit_position = result.position
		var hovered_hex = world_to_axial(hit_position)
		
		# 1. Update the target destination for the cursor
		target_position = axial_to_world(hovered_hex)
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

# Listen for mouse clicks anywhere in the viewport
func _input(event: InputEvent) -> void:
	
		

# This function runs automatically every physics frame
func _physics_proces2(_delta: float) -> void:
	var mouse_pos = get_viewport().get_mouse_position()
	var ray_origin = project_ray_origin(mouse_pos)
	var ray_end = ray_origin + project_ray_normal(mouse_pos) * 1000.0
	
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
	query.collide_with_bodies = true
	
	var result = space_state.intersect_ray(query)
	
	if result and result.collider is StaticBody3D:
		var hit_position = result.position
		var hovered_hex = world_to_axial(hit_position)
		
		# Only animate if the mouse has moved to a NEW hex
		if hovered_hex != current_hovered_hex:
			current_hovered_hex = hovered_hex
			_animate_cursor_to_hex(hovered_hex, hit_position.y)

# --- NEW: Smooth Animation Logic ---
func _animate_cursor_to_hex(hex: Vector2, terrain_height: float) -> void:
	if not hex_cursor:
		return
		
	# Calculate the target 3D position
	var target_pos = axial_to_world(hex)
	target_pos.y = terrain_height + 0.05 # Add slight offset to prevent clipping
	
	hex_cursor.visible = true
	
	# If a previous tween is still running, kill it so they don't fight
	if cursor_tween and cursor_tween.is_valid():
		cursor_tween.kill()
		
	# Create a new Tween for the smooth slide
	cursor_tween = create_tween()
	
	# TRANS_CUBIC and EASE_OUT give it a snappy start and a soft deceleration
	cursor_tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	
	# Animate the 'global_position' property to 'target_pos' over 0.15 seconds
	cursor_tween.tween_property(hex_cursor, "global_position", target_pos, 0.005)


# --- Helper Functions ---
# (Assuming you already have world_to_axial written elsewhere or below this)

func pick_hex_at_mouse() -> void:
	var camera = get_viewport().get_camera_3d()
	if not camera:
		return
		
	# 1. Get mouse position and project a ray into 3D space
	var mouse_pos = get_viewport().get_mouse_position()
	var ray_origin = camera.project_ray_origin(mouse_pos)
	var ray_end = ray_origin + camera.project_ray_normal(mouse_pos) * 1000.0
	
	# 2. Query Godot's physics space state
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
	query.collide_with_bodies = true
	
	var result = space_state.intersect_ray(query)
	
	# 3. If the ray hits our terrain body
	if result and result.collider is StaticBody3D:
		var hit_position = result.position # Exact Vector3 point on the terrain slope
		var clicked_hex = HexUtils.world_to_axial(hit_position)
		
		print("Successfully clicked Hex -> q: ", clicked_hex.x, ", r: ", clicked_hex.y)
		
		if hex_cursor:
			# 1. Get the exact center of the hex in 3D space
			var hex_center_3d = HexUtils.axial_to_world(clicked_hex)
			
			# 2. Adjust the Y (height) axis. 
			# If using a Decal, you can just set the Y high enough to project downward.
			# If using a MeshInstance on flat terrain, add a tiny offset to prevent Z-fighting.
			# If using a MeshInstance on uneven terrain, use the raycast's hit_position.y
			hex_center_3d.y = hit_position.y + 0.05 
			
			# 3. Teleport the cursor and make it visible
			hex_cursor.global_position = hex_center_3d
			hex_cursor.visible = true
		# TODO: Trigger game logic here (e.g., spawn a token, select a tile, highlight border)
