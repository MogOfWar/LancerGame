@abstract
extends Resource
class_name Ability

enum ActionType {
	QUICK_ACTION = 0,
	FULL_ACTION,
	MOVEMENT,
	REACTION,
	FREE,
	
	NUM_ACTION_TYPES
}

enum RefreshPolicy {
	ON_TURN_START,
	ON_ROUND_START
}

var ability_name_: String = ""
var action_type_: ActionType
var ui_name_: String = ""
var effects_: Dictionary[String,Array] = {}
var charges_: int = 0
var max_charges_: int = 0
var refresh_policy_: RefreshPolicy = RefreshPolicy.ON_TURN_START

func refresh():
	charges_ = max_charges_

func _init(name: String, ac_type: ActionType, max_charges: int):
	ability_name_ = name
	action_type_ = ac_type
	ui_name_ = name
	max_charges_ = max_charges
	charges_ = max_charges_

func get_ui_name() -> String:
	return ui_name_
	
func get_effect_groups_names() -> Array[String]:
	return effects_.keys()

func has_optional_abilities() -> bool:
	return false

func get_effet_group_by_name(key: String) -> Array[Effect]:
	if effects_.has(key):
		return effects_[key]
	else:
		Utils.log_error("unkown effect group")
		return []
