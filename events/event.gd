@abstract
extends RefCounted
class_name Event

enum EventType {
	Move,
}

var type_: EventType

func _init(type: EventType):
	type_ = type

@abstract func apply()
@abstract func to_log()
@abstract func get_sent_packet() -> Array
