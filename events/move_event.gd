extends Event
class_name MoveEvent

var unit_id_: int
var target_hex_qry_: Vector3

func _init(params: Array):
	super._init(EventType.Move)
	unit_id_ = params[0]
	target_hex_qry_ = Vector3(params[1], params[2], params[3])
	
func apply():
	var level: Level = Level.get_current_level()
	var unit: UnitData = level.get_unit_by_id(unit_id_)
	level.game_board_.units.erase(unit.get_pos_qr())
	unit.move(target_hex_qry_, 1)
	level.game_board_.units[Vector2i(target_hex_qry_.x, target_hex_qry_.y)] = unit

func to_log():
	pass

func get_sent_packet() -> Array:
	return [type_, unit_id_, target_hex_qry_.x, target_hex_qry_.y, target_hex_qry_.z]
