extends Resource
class_name Effect

enum TargetType {
	SELF,
	HEX,
	ANY,
	ENEMY,
	NONE,
}

@export var target_type_: TargetType = TargetType.NONE

func apply(action_context: ActionContext):
	Utils.log_error("Virtual method should have been implemented")
		
func require_targeting() -> bool:
	return target_type_ != TargetType.NONE

# return viable hexes in axial coordinates
func get_viable_targets(context: ActionContext) -> Array[Vector2i]:
	Utils.log_error("Virtual method should have been implemented")
	return []
