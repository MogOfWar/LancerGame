extends Event
class_name LogEvent

var msg_: String

func _init(msg: String):
	super._init(EventType.LOG)
	msg_ = msg

func apply():
	pass

func to_log() -> String:
	return msg_

func get_sent_packet() -> Array:
	return [type_, msg_]
