extends Resource
class_name StatusCondition

enum ConditionTrigger {
	ATTACK_TRIGGER,
	DEFENSE_TRIGGER,
	ALL_CHECKS,
	ALL,
	NONE
}

enum StatusConditionType {
	ACC_MODIFER,
	DAMAGE_RESISTANCE,
	STUNNED,
	SLOWED,
	NONE
}

@export var type_: StatusConditionType = StatusConditionType.NONE
@export var acc_modifer_: int = 0
@export var damage_type_: Constants.DamageType = Constants.DamageType.KINETIC
@export var trigger_: ConditionTrigger = ConditionTrigger.NONE
@export var time_: int

static func create_basic_defense_accuracy() -> StatusCondition:
	var ret: StatusCondition = StatusCondition.new(StatusConditionType.ACC_MODIFER, ConditionTrigger.DEFENSE_TRIGGER, 2)
	ret.acc_modifer_ = -1
	return ret
	
static func create_basic_damage_resistance() -> StatusCondition:
	var ret: StatusCondition = StatusCondition.new(StatusConditionType.DAMAGE_RESISTANCE, ConditionTrigger.DEFENSE_TRIGGER, 2)
	ret.damage_type_ = Constants.DamageType.KINETIC
	return ret

func _init(type: StatusConditionType, trigger: ConditionTrigger, time):
	type_ = type
	trigger_ = trigger
	time_ = time

func is_triggered_for_defense() -> bool:
	return trigger_ == ConditionTrigger.DEFENSE_TRIGGER
	
func is_triggered_for_attack() -> bool:
	return trigger_ == ConditionTrigger.ATTACK_TRIGGER or trigger_ == ConditionTrigger.ALL_CHECKS
