@abstract
extends Resource
class_name Event

enum EventType {
	MOVE,
	WEAPON_FIRE,
	ROLL,
	DAMAGE,
	STATUS,
	UNIT_SPAWN,
	LOG
}

var type_: EventType

func _init(type: EventType):
	type_ = type

@abstract func apply()
@abstract func to_log() -> String
@abstract func get_sent_packet() -> Array
