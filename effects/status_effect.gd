extends Effect
### effect that grants a condition to a unit
class_name StatusEffect

@export var conditions_: Array[StatusCondition]
@export var skip_current_turn_: bool = true # enable to do until next turn

func apply(action_context: ActionContext, target_hex: Vector2i):
	var gb: GameBoard = action_context.game_board_
	var src_unit: UnitData = action_context.source_unit_
	var affected_hexes: Array[Vector2i] = gb.get_affected_hexes(target_hex, self, src_unit.get_pos_qr())

	for target_unit in get_affected_units(affected_hexes):
		if target_unit != null:
			for cond in conditions_:
				var new_cond: StatusCondition = cond.make_copy()
				if Level.get_current_level().turn_manager_.current_player_turn_ == src_unit.own_player_id_ and skip_current_turn_:
					new_cond.time_ += 1
				Level.get_current_level().event_manager_.handle_event(StatusEvent.new(target_unit.unit_id_, new_cond))
