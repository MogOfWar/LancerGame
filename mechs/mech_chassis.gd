extends Resource
class_name MechChassis

enum MountType { 
	HEAVY = 0,
	MAIN, 
	MAIN_AUX, 
	UNDEFINED
}
const MOUNT_TYPE_NAMES = {
	MountType.HEAVY: "Heavy",
	MountType.MAIN: "Main",
	MountType.MAIN_AUX: "Main/Aux"
}

class MountData:
	var mount_type_
	var num_

static func get_mount_type_name(m: MountType) -> String:
	if m == MountType.UNDEFINED:
		Utils.log_error("Undefind Mount")
		return ""
	else:
		return MOUNT_TYPE_NAMES[m]

@export var chassis_name_: String = ""
@export var size_: int = 0
@export var armor_: int = 0
@export var max_hp_: int = 0
@export var repair_cap_: int = 0
@export var evasion_: int = 0
@export var speed_: int = 0
@export var save_target_: int = 0
@export var sensors_: int = 0
@export var e_def_: int = 0
@export var tech_attack_: int = 0
@export var max_system_point_: int = 0
@export var heat_cap_: int = 0
@export var mounts_: Array[ChassisMount] = []
