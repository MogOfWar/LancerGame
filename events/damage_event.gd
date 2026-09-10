extends Event
class_name DamageEvent

var src_unit_id_: int
var unit_damaged_id_: int
var damage_val_: int
var damage_type_: Constants.DamageType
var is_hit_: bool
var is_crit_: bool
var prev_hp_: int
var new_hp_: int

func _init(params: Array):
	super._init(EventType.DAMAGE)
	unit_damaged_id_ = params[0]
	src_unit_id_ = params[1]
	damage_val_ = params[2]
	damage_type_ = params[3]
	is_hit_ = params[4]
	is_crit_ = params[5]
	
func to_log():
	var ret = "unit %s recived %s damage of type %s (hp %s -> %s)" % [unit_damaged_id_, damage_val_, damage_type_, prev_hp_, new_hp_]
	return ret	
	
func apply():
	var unit: UnitData = Level.get_current_level().get_unit_by_id(unit_damaged_id_)
	var src_unit: UnitData = Level.get_current_level().get_unit_by_id(src_unit_id_)
	if not is_hit_:
		return
	var modified_damage: int = damage_val_
	for cond in unit.conditions_:
		if cond.type_ == StatusCondition.StatusConditionType.DAMAGE_RESISTANCE:
			modified_damage *= 0.5		
	prev_hp_ = unit.hp_
	new_hp_ = max(prev_hp_ - modified_damage, 0)
	unit.hp_ -= modified_damage
	if unit.hp_ > 0:
		SignalBus.unit_damaged.emit(unit, src_unit, modified_damage)
	if unit.hp_ <= 0:
		SignalBus.unit_died.emit(unit)

func get_sent_packet() -> Array:
	return [type_, unit_damaged_id_, src_unit_id_, damage_val_, damage_type_, is_hit_, is_crit_]
