class_name CameraPivot
extends Node3D

@export_group("Pan Settings")
@export var pan_speed: float = 20.0
@export var drag_sensitivity: float = 0.03

@export_group("Zoom Settings")
@export var zoom_speed: float = 2.0
@export var min_zoom: float = 5.0
@export var max_zoom: float = 75.0
@export var zoom_smoothness: float = 10.0

@onready var camera: Camera3D = $CameraArm/Camera3D
@onready var target_zoom: float = camera.position.z

var is_dragging: bool = false

func get_camera() -> Camera3D:
	return camera

func _unhandled_input(event: InputEvent) -> void:
	# --- Scroll Wheel Zooming ---
	if event is InputEventMouseButton and event.is_pressed():
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			target_zoom = clamp(target_zoom - zoom_speed, min_zoom, max_zoom)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			target_zoom = clamp(target_zoom + zoom_speed, min_zoom, max_zoom)

	# --- Middle Mouse Dragging ---
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_MIDDLE:
		is_dragging = event.pressed

	if event is InputEventMouseMotion and is_dragging:
		# Move the pivot along the XZ ground plane relative to mouse movement
		var drag_dir := Vector3(-event.relative.x, 0, -event.relative.y) * drag_sensitivity
		global_position += global_transform.basis * drag_dir
		
		

func _process(delta: float) -> void:
	# --- WASD / Arrow Key Panning ---
	var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var move_dir := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if move_dir != Vector3.ZERO:
		global_position += move_dir * pan_speed * delta

	# --- Smooth Zoom Interpolation ---
	
	camera.position.z = lerp(camera.position.z, target_zoom, zoom_smoothness * delta)	
