extends VisualEvent
class_name WeaponFireVisualEvent

var src_unit_: Unit
var target_global_pos_: Vector3

func _init(src_unit: Unit, target_global_pos: Vector3):
	src_unit_ = src_unit
	target_global_pos_ = target_global_pos

func execute() -> void:
	src_unit_.play_attack_animation(target_global_pos_)
	await VFXManager.spawn_projectile(src_unit_, target_global_pos_)
	src_unit_.play_idle_animation()
	super.execute()
