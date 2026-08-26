extends Ability
class_name MoveAbility

func _init():
	super._init("Move", Ability.ActionType.MOVEMENT)
	var move_effect = MoveEffect.new()
	move_effect.target_type_ = Effect.TargetType.HEX
	effects_.append(move_effect)
