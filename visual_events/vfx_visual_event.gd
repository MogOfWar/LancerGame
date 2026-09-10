extends VisualEvent
class_name VFXVisualEvent

var method_: Callable

func _init(method: Callable):
	method_ = method

func execute() -> void:
	await method_.call()
	super.execute()
