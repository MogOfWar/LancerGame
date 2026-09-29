extends VisualEvent
class_name WeaponFireVisualEvent

var src_unit_: Unit
var target_global_pos_: Vector3
var animation_id_: int

func _init(src_unit: Unit, target_global_pos: Vector3, animation_id):
	src_unit_ = src_unit
	target_global_pos_ = target_global_pos
	animation_id_ = animation_id

func execute() -> void:
	src_unit_.play_attack_animation(target_global_pos_, animation_id_)
	if animation_id_ == 0:
		await VFXManager.spawn_projectile(src_unit_, target_global_pos_)
	src_unit_.play_idle_animation()
		
	super.execute()
