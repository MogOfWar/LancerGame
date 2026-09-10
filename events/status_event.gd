extends Event
class_name StatusEvent

var cond_ : StatusCondition
var unit_id_: int

func _init(unit_id: int, cond: StatusCondition):
	super._init(EventType.STATUS)
	cond_ = cond
	unit_id_ = unit_id

func apply():
	var level: Level = Level.get_current_level()
	var unit: UnitData = level.get_unit_by_id(unit_id_)
	unit.apply_condition(cond_)
	
func to_log() -> String:
	return "unit %s got condition %s" % [unit_id_, cond_.type_]
	
func get_sent_packet() -> Array:
	return [type_, unit_id_, cond_.serialize()]
