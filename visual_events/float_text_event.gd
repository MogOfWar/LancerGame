extends VisualEvent
class_name FloatingTextVisualEvent

var params_: Dictionary

func _init(params: Dictionary) -> void:
	params_ = params

func execute() -> void:
	await VFXManager.spawn_text(params_)
	super.execute()
