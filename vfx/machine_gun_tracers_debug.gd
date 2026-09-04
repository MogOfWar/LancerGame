@tool
extends GPUParticles3D

@export var debug_target: Node3D # Drag a dummy MeshInstance here in the editor to act as the enemy
@export var fire_test: bool = false:
	set(value):
		if debug_target:
			_run_debug_fire()
		fire_test = false

func _run_debug_fire() -> void:
	if not finished.is_connected(_on_finished):
		finished.connect(_on_finished)
	# Mimic what your visual_manager will do
	look_at(debug_target.global_position, Vector3.UP)
	# Reset and fire
	restart()
	$MuzzleFlash.restart()
	$MuzzleFlash2.restart()
	var emit_duration = lifetime * (1-explosiveness)
	emitting = true
	$MuzzleFlash.emitting = true
	$MuzzleFlash2.emitting = true
	await get_tree().create_timer(emit_duration).timeout
	$MuzzleFlash.emitting = false
	$MuzzleFlash2.emitting = false
	emitting = false
	
	# Optional: Print travel time to output so you can verify your math
	var dist = global_position.distance_to(debug_target.global_position)
	var speed = process_material.initial_velocity_max
	print("Expected travel time: ", dist / speed, " seconds")

func _on_finished() -> void:
	print("all bullets fired")
	$MuzzleFlash.emitting = false 
	$MuzzleFlash2.emitting = false
	$MuzzleFlash.one_shot = true
	$MuzzleFlash2.one_shot = true
