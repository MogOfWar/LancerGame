extends Resource
class_name WeaponType

enum TargetMode {Single, Blast, Cone, Burst}

@export var weapon_name_: String = ""
@export var damage: Array[int] = []
@export var extra_damage: int = 0
@export var weapon_scene: PackedScene
@export var range: int = 0
@export var target_mode_: TargetMode = TargetMode.Single
@export var target_mode_radius_: int = 0

func roll_damage() -> int:
	var total_damage: int = extra_damage
	for i in range(len(damage)):
		for j in range(damage[i]):
			total_damage += randi_range(1, 3*i)
	return total_damage
