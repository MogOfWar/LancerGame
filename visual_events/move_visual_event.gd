extends VisualEvent
class_name MoveVisualEvent


var params_: Dictionary

func _init(params: Dictionary) -> void:
	params_ = params

func execute() -> void:
	var unit: Unit = params_["unit"]
	var src: Vector3 = params_["src"]
	var dst: Vector3 = params_["dst"]
	await unit.move(src, dst)
	super.execute()
