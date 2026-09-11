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
	var level: Level = Level.get_current_level()
	level.event_manager_.handle_event(WeaponFireEvent.new([src_unit.unit_id_, target_hex.x, target_hex.y, 1, target_mode_]))
	for target_unit in get_affected_units(affected_hexes):
			var is_hit: bool = true
			var is_crit: bool = false
			var damage_val: int = 0
			if src_unit.get_attack_override(): 
				is_hit = true
			elif target_unit.get_defense_override():
				is_hit = false
			else:
				var accuracy: int = src_unit.get_attack_accuracy()
				accuracy += target_unit.get_defense_accuracy()
				var attack_res: Vector2i = gb.roll_attack(src_unit, target_unit, accuracy)
				var attack_roll: int = attack_res.x + attack_res.y
				var target_evasion: int = target_unit.get_evasion()
				level.event_manager_.handle_event(RollEvent.new([attack_res.x, attack_res.y, target_evasion, RollEvent.RollType.ATTACK]))
				if attack_roll > target_evasion:
					is_hit = true
				if attack_roll > 20:
					is_crit = true
				if is_hit: 
					damage_val = roll_damage()
					if is_crit:
						damage_val = max(damage_val, roll_damage())
					await action_context.reaction_manager_.handle_reaction(
						action_context,
						self,
						{
							ReactionManager.REACTION_TYPE_KEY: ReactionManager.ReactionType.ATTACK_DAMAGE, 
							"target_unit": target_unit
						}
						
					)
				level.event_manager_.handle_event(DamageEvent.new([target_unit.unit_id_, src_unit.unit_id_, damage_val, damage_type_, is_hit, is_crit]))
