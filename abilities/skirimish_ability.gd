extends Ability
class_name  SkirimishAbility

const NAME: String = "Skrimish"

var weapon_: WeaponInstance2

func _init(weap: WeaponInstance2):
	super._init(NAME, Ability.ActionType.QUICK_ACTION)
