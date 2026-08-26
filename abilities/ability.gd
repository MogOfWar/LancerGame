extends RefCounted
class_name Ability

enum ActionType {
	QUICK_ACTION,
	FULL_ACTION,
	MOVEMENT,
	REACTION,
	FREE,
}

var ability_name_: String = ""
var action_type_: ActionType
var ui_name_: String = ""
var effects_: Array[Effect] = []

func _init(name: String, ac_type: ActionType):
	ability_name_ = name
	action_type_ = ac_type
	ui_name_ = name

func get_ui_name() -> String:
	return ui_name_
	
func get_effects() -> Array[Effect]:
	return effects_
