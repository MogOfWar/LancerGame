extends Effect
### effect that grants a condition to a unit
class_name StatusEffect

@export var conditions_: Array[StatusCondition]

func apply(action_context: ActionContext, target_hex: Vector2i):
	var gb: GameBoard = action_context.game_board_
	var src_unit = action_context.source_unit_
	var affected_hexes: Array[Vector2i] = gb.get_affected_hexes(target_hex, self, src_unit.get_pos_qr())
	for target_unit in get_affected_units(affected_hexes):
		if target_unit != null:
			for cond in conditions_:
				Level.get_current_level().event_manager_.handle_event(StatusEvent.new(target_unit.unit_id_, cond))
