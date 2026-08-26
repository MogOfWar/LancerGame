extends Effect
class_name MoveEffect

func apply(context: ActionContext, target):
	var hex_qr = target[0]
	context.game_board_.move_unit(context.source_unit_, hex_qr)
	
func get_viable_targets(context: ActionContext) -> Array[Vector2i]:
	var total_speed = context.source_unit_.get_movement_points()
	return context.game_board_.get_movement_range(context.source_unit_.get_pos_qr(), total_speed)

func get_preview(context: ActionContext, target_qr: Vector2i) -> Array[Vector2i]:
	return context.game_board_.get_move_path(context.source_unit_.get_pos_qr(), target_qr)
