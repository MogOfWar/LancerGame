extends Unit
class_name  UnitPawn

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super._ready()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func move(src_qry: Vector3, hex_qry: Vector3):
	$Boosters/JetTrails/JetExhaust.emitting = true
	$Boosters/JetTrails/SmokeTrail.emitting = true
	var target_position: Vector3 = calc_location_from_qry(hex_qry)
	target_position.y = hex_qry.z
	var distance = global_position.distance_to(target_position)
	var duration = distance / 2.0
	
	# 2. Face the target before moving
	# We flatten the Y axis for the look_at target so the unit doesn't tilt up/down slopes
	var flat_target = Vector3(target_position.x, global_position.y, target_position.z)
	
	# Optional: Prevent look_at error if already standing exactly at the target
	if global_position.distance_to(flat_target) > 0.01:
		look_at(flat_target, Vector3.UP, true)

	var tween = create_tween()
	var start_pos = position
	
	# Set ease/trans if you want acceleration/deceleration, or leave linear for constant speed
	tween.set_trans(Tween.TRANS_LINEAR)
	
	await tween.tween_method(
		func(t: float): _update_arc_position(start_pos, target_position, t),
		0.0,
		1.0,
		duration
	)
	# Animate the global_position to the target. 
	# Because target_position includes the new Y height, the Tween automatically handles the slope.
	#tween.tween_property(self, "global_position", target_position, duration)
	await tween.finished
	$Boosters/JetTrails/JetExhaust.emitting = false
	$Boosters/JetTrails/SmokeTrail.emitting = false
	
func _update_arc_position(start: Vector3, target: Vector3, t: float) -> void:
	# Linear position between start and target
	var current_pos = start.lerp(target, t)
	
	# Parabola formula: peaks at t = 0.5 with height = arc_height
	# In 2D, negative Y is upward
	var arc_height = 2.0
	var height_offset = 4.0 * arc_height * t * (1.0 - t)
	current_pos.y += height_offset
	
	position = current_pos

func play_attack_animation(tar_global_pos: Vector3) -> void:
	pass
	
func play_idle_animation() -> void:
	pass
	
func get_weapon_global_pos() -> Vector3:
	return $Muzzle.global_position
