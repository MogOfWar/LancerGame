extends VisualEvent
class_name WeaponFireVisualEvent

var src_unit_: Unit
var target_global_pos_: Vector3

func _init(src_unit: Unit, target_global_pos: Vector3):
	src_unit_ = src_unit
	target_global_pos_ = target_global_pos

func execute() -> void:
	VFXManager.spawn_projectile(src_unit_, target_global_pos_)
	super.execute()
