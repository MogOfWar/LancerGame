extends RefCounted
class_name VisualEvent

signal finished

# The method the queue will call to start the visual sequence
func execute() -> void:
	# Child classes will override this with their specific animation logic.
	# When they are done, they MUST emit 'finished'.
	finished.emit()
