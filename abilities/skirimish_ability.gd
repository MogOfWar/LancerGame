extends Ability
class_name  SkirimishAbility

const NAME: String = "Skrimish"
var unit_data_: UnitData

func _init(id: int, unit_data: UnitData):
	super._init(id, NAME, Ability.ActionType.QUICK_ACTION, 1)
	unit_data_ = unit_data
	
func get_effect_groups_names() -> Array[String]:
	effects_.clear()
	# updating list of available weapons each time in case one got destroyed
	# this might be a perf issue later on
	var weapon_instances: Array[UnitData.WeaponInstance] = unit_data_.get_mounts()
	for wi in weapon_instances:
		effects_[wi.get_ui_string()] = wi.weapon_.effects_
	return effects_.keys()		

func has_optional_abilities() -> bool:
	return true
