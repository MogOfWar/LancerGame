extends Event
class_name MoveEvent

var unit_id_: int
var target_hex_qry_: Vector3
var old_pos_: Vector3

func _init(params: Array):
	super._init(EventType.MOVE)
	unit_id_ = params[0]
	target_hex_qry_ = Vector3(params[1], params[2], params[3])
	
func apply():
	
	var level: Level = Level.get_current_level()
	var unit: UnitData = level.get_unit_by_id(unit_id_)
	old_pos_ = unit.get_pos_qry()
	level.game_board_.update_unit_location(unit, target_hex_qry_)

func to_log() -> String:
	return "unit %s moved from %s to %s" % [unit_id_, old_pos_, target_hex_qry_]

func get_sent_packet() -> Array:
	return [type_, unit_id_, target_hex_qry_.x, target_hex_qry_.y, target_hex_qry_.z]
