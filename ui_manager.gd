# ui_manager.gd
extends CanvasLayer

# A dictionary to link 3D units to their 2D UI widgets
var active_widgets: Dictionary = {}
@export var widget_health_scene_: PackedScene
@export var ui_scale_factor: float = 15.0

func _ready():
	SignalBus.unit_spawned.connect(_on_unit_spawned)
	SignalBus.unit_died.connect(_on_unit_died)
	
func _on_unit_spawned(unit: Unit):
	var health_widget = widget_health_scene_.instantiate()
	add_child(health_widget)
	
	# 2. Store the pair in our dictionary
	active_widgets[unit] = health_widget
	health_widget.setup(unit.hp_)
	unit.register_health_bar(health_widget)


func _on_unit_died(unit: Unit):
	# Clean up the UI when the unit dies or is removed
	if active_widgets.has(unit):
		active_widgets[unit].queue_free()
		active_widgets.erase(unit)

func _process(_delta):
	var current_camera = get_viewport().get_camera_3d()
	if not current_camera:
		return
		
	for unit in active_widgets:
		var widget = active_widgets[unit]
		var target_3d_position = Vector3.ZERO
		# Look for the UIMarker we placed earlier
		var marker = unit.get_node_or_null("UI_Anchor")
		if marker:
			target_3d_position = marker.global_position
		else:
			# Fallback if no marker exists
			target_3d_position = unit.global_position + Vector3(0, 2, 0)
		
		# PRO TIP: If you don't check if the position is behind the camera, 
		# Godot will project the UI onto the screen inversely when looking away!
		if current_camera.is_position_behind(target_3d_position):
			widget.hide()
		else:
			widget.show()
			var screen_pos = current_camera.unproject_position(target_3d_position)
			# --- THE FLAWLESS DIEGETIC MATH ---
			
			# 1. Get a point exactly 1 meter to the right of the unit 
			# (Aligned perfectly with the camera's lens using basis.x)
			var camera_right_vector = current_camera.global_transform.basis.x
			var offset_3d_position = target_3d_position + camera_right_vector
			
			# 2. Find where that 1-meter offset is on your 2D screen
			var offset_screen_pos = current_camera.unproject_position(offset_3d_position)
			
			# 3. Calculate the distance between them. 
			# This is exactly how many pixels "1 meter" takes up on screen right now!
			var pixels_per_meter = screen_pos.distance_to(offset_screen_pos)
			
			# 4. Set how wide you want the bar to be in the 3D world (e.g., 1.5 meters)
			var desired_width_in_meters = 1.0 
			
			# 5. Calculate the perfect scale multiplier
			var perfect_scale = (pixels_per_meter / widget.size.x) * desired_width_in_meters
			
			# Optional: You can still clamp it so it doesn't get completely 
			# microscopic from across the map, but we raise the max cap!
			perfect_scale = clamp(perfect_scale, 0.1, 5.0)
			
			# Apply the scale and perfectly center it
			widget.scale = Vector2(perfect_scale, perfect_scale)
			widget.position = screen_pos - ((widget.size * widget.scale) / 2.0)
