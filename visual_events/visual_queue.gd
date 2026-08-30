class_name VisualQueue
extends Node

var queue_: Array[VisualEvent] = []
var is_playing_: bool = false
var playing_event_: VisualEvent = null

# Allows you to block player input while animations are playing
signal queue_started
signal queue_empty

func add_event(event: VisualEvent) -> void:
	queue_.append(event)
	if not is_playing_:
		_play_next()

func _play_next() -> void:
	if queue_.is_empty():
		is_playing_ = false
		queue_empty.emit()
		return
		
	if not is_playing_:
		is_playing_ = true
		queue_started.emit()

	playing_event_ = queue_.pop_front()
	
	# Connect the finished signal to trigger the next item in the queue
	playing_event_.finished.connect(_play_next)
	
	# Start the action
	playing_event_.execute()
