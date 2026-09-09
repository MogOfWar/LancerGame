extends Node
class_name EventManager

var events_: Array[Event]
var log_: bool = false
func handle_event(event: Event):
	event.apply()
	if log_:
		print(event.to_log())
	events_.append(event)
