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

@export var target_type_: TargetType = TargetType.NONE

@abstract
func apply(action_context: ActionContext, target_hexes)

		
func require_targeting() -> bool:
	return target_type_ != TargetType.NONE

# return viable hexes in axial coordinates
@abstract
func get_viable_targets(context: ActionContext) -> Array[Vector2i]
