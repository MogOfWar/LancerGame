extends Resource
class_name WeaponType

enum TargetMode {Single, Blast, Cone, Burst, Line}

@export var weapon_name_: String = ""
@export var damage: Array[int] = []
@export var extra_damage: int = 0
@export var weapon_scene: PackedScene
@export var range: int = 0
@export var target_mode_: TargetMode = TargetMode.Single
@export var target_mode_radius_: int = 0
@export var effects_: Array[Effect] = []
