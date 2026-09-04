extends GPUParticles3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func shoot(target: Vector3) -> void:
	# Mimic what your visual_manager will do
	var distance = global_position.distance_to(target)
	var process_mat = process_material as ParticleProcessMaterial
	var bullet_speed = process_mat.initial_velocity_max
	if bullet_speed <= 0:
		bullet_speed = 1.0
	var travel_time = distance / bullet_speed
	lifetime = travel_time
	look_at(target, Vector3.UP)
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
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
