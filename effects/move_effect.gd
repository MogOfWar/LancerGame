extends Effect
class_name MoveEffect

func apply(context: ActionContext, target_qr: Vector2i):
	var game_board: GameBoard = Level.get_current_level().game_board_
	var unit = context.source_unit_
	
	# check for overwatch
	await context.reaction_manager_.handle_reaction(
						context,
						self,
						{
							ReactionManager.REACTION_TYPE_KEY: ReactionManager.ReactionType.MOVE, 
							"target_unit": context.source_unit_
						}
						
					)
	# check if unit can move?
	
	var move_path = game_board.get_move_path(unit, unit.get_pos_qr(), target_qr)
	for hex_qr in move_path:
		if hex_qr == unit.get_pos_qr():
			continue
		else:
			var new_event = MoveEvent.new([unit.unit_id_, hex_qr.x, hex_qr.y, game_board.grid_.get_height_from_qr(hex_qr)])
			Level.get_current_level().event_manager_.handle_event(new_event)
	
func get_viable_targets(context: ActionContext) -> Array[Vector2i]:
	var total_speed = context.source_unit_.get_movement_points()
	var size = context.source_unit_.get_size()
	return context.game_board_.get_movement_range(context.source_unit_.get_pos_qr(), total_speed, size)
