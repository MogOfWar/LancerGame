extends Ability
class_name BraceAbility

func _init():
	refresh_policy_ = RefreshPolicy.ON_ROUND_START
	super._init("Brace", ActionType.REACTION, 1)
	var conditions: Array[StatusCondition] = []
	conditions.append(StatusCondition.create_basic_defense_accuracy())
	conditions.append(StatusCondition.create_basic_damage_resistance())
	var effect: StatusEffect = StatusEffect.new()
	effect.conditions_ = conditions
	effect.target_type_ = Effect.TargetType.SELF
	effects_["0"] = [effect]
	charges_ = 1
	
func get_reaction() -> ReactionManager.Reaction:
	var new_rec: ReactionManager.Reaction = ReactionManager.Reaction.new()
	new_rec.ability = self
	new_rec.sub_name = "0"
	new_rec._cond = func(reaction_context) -> bool:
		return reaction_context["unit_dst_ability"] == reaction_context["unit_reacting"]
	return new_rec

func get_reaction_type() -> ReactionManager.ReactionType:
	return ReactionManager.ReactionType.ATTACK_DAMAGE
	
