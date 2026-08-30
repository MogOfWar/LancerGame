@abstract 
extends Resource
class_name Effect

enum TargetType {
	SELF,
	HEX,
	ANY,
	ENEMY,
	NONE,
}

enum TargetMode {Single, Blast, Cone, Burst, Line}

@export var target_type_: TargetType = TargetType.NONE
@export var target_mode_: TargetMode = TargetMode.Single
@export var target_mode_radius_: int = 0

@abstract func apply(action_context: ActionContext, target_hex: Vector2i)

func get_server_packet() -> Effect:
	return self
		
func require_targeting() -> bool:
	return target_type_ != TargetType.NONE

# return viable hexes in axial coordinates
@abstract func get_viable_targets(context: ActionContext) -> Array[Vector2i]
@abstract func get_ui_name()
