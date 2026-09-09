extends PlayerController
class_name RemotePlayerController

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


func get_picked_hexes(context: ActionContext, viable_hexes: Array[Vector2i], effect: Effect) -> Vector2i:
	return Vector2i(-1,-1)

func choose_reaction(context: ActionContext, src_ability: Ability, src_effect: Effect, reaction_params: Dictionary, reacting_unit: UnitData, valid_reactions: Array[ReactionManager.Reaction]) -> ReactionManager.Reaction:
	return null

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
