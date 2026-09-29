extends Ability
class_name OverwatchAbility

const NAME: String = "Overwatch"
var unit_data_: UnitData

func _init(id: int, unit_data: UnitData):
	super._init(id, NAME, Ability.ActionType.REACTION, 1)
	unit_data_ = unit_data
	
func get_effect_groups_names() -> Array[String]:
	return effects_.keys()		

func update_effect_list() -> void:
	effects_.clear()
	# updating list of available weapons each time in case one got destroyed
	# this might be a perf issue later on
	var weapon_instances: Array[UnitData.WeaponInstance] = unit_data_.get_mounts()
	for wi in weapon_instances:
		for eff in wi.weapon_.effects_:
			if eff is DamageEffect and (eff as DamageEffect).threat_range_ > 0:
				effects_.get_or_add(wi.get_ui_string(), []).append(eff)

func has_optional_abilities() -> bool:
	return true
	
func get_reaction() -> ReactionManager.Reaction:
	var new_rec: ReactionManager.Reaction = ReactionManager.Reaction.new()
	if not effects_.is_empty():
		new_rec.ability = self
		new_rec.sub_name = effects_.keys()[0]
		new_rec._cond = func(reaction_context) -> bool:
			var effects = effects_[effects_.keys()[0]]
			if effects.is_empty():
				return false
			else:
				var target_unit = reaction_context["unit_src_ability"]
				var range_to_target = HexUtils.get_axial_distance(unit_data_.get_pos_qr(), target_unit.get_pos_qr())
				for eff: DamageEffect in effects:
					if range_to_target <= eff.threat_range_:
						return true
			return false
					
		return new_rec
	else:
		return null

func get_reaction_type() -> ReactionManager.ReactionType:
	return ReactionManager.ReactionType.MOVE
