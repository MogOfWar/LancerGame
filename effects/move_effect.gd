extends Effect
class_name MoveEffect

func apply(action_context: ActionContext):
	pass
	
func get_viable_targets(context: ActionContext) -> Array[Vector2i]:
	var total_speed = context.source_unit.get_movement_points()
	return context.game_board.get_movement_range(context.source_unit.current_hex, total_speed)
