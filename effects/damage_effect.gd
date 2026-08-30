extends Effect
class_name DamageEffect



@export var damage: Array[int] = []
@export var extra_damage: int = 0
@export var range: int = 0


func _init():
	target_type_ = TargetType.ENEMY

func roll_damage() -> int:
	var total_damage: int = extra_damage
	for i in range(len(damage)):
		for j in range(damage[i]):
			total_damage += randi_range(1, 3*(i+1))
	return total_damage


func apply(action_context: ActionContext, target_hex: Vector2i):
	var gb: GameBoard = action_context.game_board_
	var src_unit = action_context.source_unit_
	var affected_hexes: Array[Vector2i] = gb.get_affected_hexes(target_hex, self, src_unit.get_pos_qr())
	for hex in affected_hexes:
		var data: GameBoard.HexData = gb.get_hex_data(hex)
		if data.unit != null:
			if gb.roll_attack(src_unit, data.unit, 0):
				var damage_val: int = roll_damage()
				gb.damage_unit(data.unit, damage_val)
				
func get_viable_targets(context: ActionContext) -> Array[Vector2i]:
	if target_type_ == TargetType.ENEMY:
		return context.game_board_.get_units_in_range(context.source_unit_.get_pos_qr(), range)
	else:
		return context.game_board_.get_hexes_qr_in_range(context.source_unit_.get_pos_qr(), range)
	
func get_ui_name():
	pass
