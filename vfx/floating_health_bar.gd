# floating_health_bar.gd
extends Control
class_name FloatingHealthBar

@onready var progress_bar: TextureProgressBar = $HPBar

# We center the pivot point so the bar is centered over the unit's head
func _ready():
	progress_bar.set_anchors_preset(Control.PRESET_CENTER)
	
func setup(max_health: int):
	progress_bar.max_value = max_health
	progress_bar.value = max_health

func update_health(current_health: int):
	progress_bar.value = current_health
