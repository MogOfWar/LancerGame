extends Ability
class_name MoveAbility

func _init():
	super._init("Move", Ability.ActionType.MOVEMENT, 1)
	var move_effect = MoveEffect.new()
	move_effect.target_type_ = Effect.TargetType.HEX
	effects_["move"] = [move_effect]
