extends Effect
class_name DamageEffect

@export var damage: Array[int] = []
@export var extra_damage: int = 0
@export var damage_type_: Constants.DamageType = Constants.DamageType.KINETIC


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
			var is_hit: bool = true
			var is_crit: bool = false
			if src_unit.get_attack_override(): 
				is_hit = true
			elif data.unit.get_defense_override():
				is_hit = false
			else:
				var accuracy: int = src_unit.get_attack_accuracy()
				accuracy += data.unit.get_defense_accuracy()
				var attack_roll: int = gb.roll_attack(src_unit, data.unit, accuracy)
				if attack_roll > data.unit.get_evasion():
					is_hit = true
				if attack_roll > 20:
					is_crit = true
				if is_hit: 
					var damage_val: int = roll_damage()
					if is_crit:
						damage_val = max(damage_val, roll_damage())
					await action_context.reaction_manager_.handle_reaction(
						action_context,
						self,
						{
							ReactionManager.REACTION_TYPE_KEY: ReactionManager.ReactionType.ATTACK_DAMAGE, 
							"target_unit": data.unit
						}
						
					)
					print("applying damage")
					gb.damage_unit(data.unit, damage_val, is_crit)
