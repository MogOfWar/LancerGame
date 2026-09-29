class_name Unit3D
extends Unit

@onready var anim_player = $AuxScene/AnimationPlayer
var speed: float = 3.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super._ready()	


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func move(src_qry: Vector3, hex_qry: Vector3):
	# 1. Calculate duration so movement speed remains consistent regardless of distance
	var target_position: Vector3 = calc_location_from_qry(hex_qry)
	target_position.y = hex_qry.z
	var distance = global_position.distance_to(target_position)
	var duration = distance / speed
	
	# 2. Face the target before moving
	# We flatten the Y axis for the look_at target so the unit doesn't tilt up/down slopes
	var flat_target = Vector3(target_position.x, global_position.y, target_position.z)
	
	# Optional: Prevent look_at error if already standing exactly at the target
	if global_position.distance_to(flat_target) > 0.01:
		look_at(flat_target, Vector3.UP, true)
	anim_player.get_animation("Ven-walk").loop_mode = Animation.LOOP_LINEAR	
	# 3. Play the walking animation
	anim_player.play("Ven-walk")
	
	# 4. Create and configure the Tween
	var tween = create_tween()
	
	# Animate the global_position to the target. 
	# Because target_position includes the new Y height, the Tween automatically handles the slope.
	tween.tween_property(self, "global_position", target_position, duration)
	
	await tween.finished
	anim_player.stop()
	
func play_attack_animation(tar_global_pos: Vector3, type: int) -> void:
	look_at(tar_global_pos, Vector3.UP, true)
	
func play_idle_animation() -> void:
	anim_player.play("Ven-fi")
	
func get_weapon_global_pos() -> Vector3:
	return $GunMuzzle.global_position
