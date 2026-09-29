extends Event
class_name WeaponFireEvent

var src_unit_id_: int
var target_qry_: Vector3
var target_mode_: Effect.TargetMode
var animation_id_: int

func _init(params: Array):
	super._init(EventType.WEAPON_FIRE)
	src_unit_id_ = params[0]
	target_qry_ = Vector3(params[1], params[2], params[3])
	target_mode_ = params[4]
	animation_id_ = params[5]

func apply():
	var level: Level = Level.get_current_level()
	var unit: UnitData = level.get_unit_by_id(src_unit_id_)
	var target_unit = level.game_board_.get_hex_data(Vector2i(target_qry_.x, target_qry_.y)).unit
	SignalBus.unit_weapon_fire.emit(unit, target_unit, animation_id_)

func to_log():
	return ""

func get_sent_packet() -> Array:
	return [type_, src_unit_id_, target_qry_.x, target_qry_.y, target_qry_.z, target_mode_, animation_id_]
