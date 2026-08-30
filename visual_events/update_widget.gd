extends VisualEvent
class_name UpdateWidgetVisualEvent

var unit_: Unit = null

func _init(unit: Unit):
	unit_ = unit
	
func execute() -> void:
	SignalBus.ui_update_health_width.emit(unit_)
	super.execute()
