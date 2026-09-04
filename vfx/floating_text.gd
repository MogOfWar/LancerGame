extends Node3D


@onready var label = $Label

# 1. Changed 'amount' to a String so it can say "Miss" or "+50"
# 2. Replaced 'is_crit' with a generic 'Color' parameter
func display(text_to_show: String, start_position: Vector3, make_large: bool = false, text_color: Color = Color.WHITE, ):
	show()
	global_position = start_position
	label.text = text_to_show
	label.modulate = text_color
	
	if make_large:
		label.scale = Vector3(2.5, 2.5, 2.5)
	else:
		label.scale = Vector3(1.0, 1.0, 1.0) # Always reset scale when reusing from a pool!

	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "global_position:y", global_position.y + 1.5, 1.0).set_ease(Tween.EASE_OUT)
	
	# Notice we use self.modulate:a instead of label.modulate:a 
	# so the whole node fades, avoiding color override issues
	tween.tween_property(label, "transparency", 1.0, 1.0).set_ease(Tween.EASE_IN)
	
	#dangerous if we ever pool
	tween.finished.connect(queue_free)
	
	# RETURN the signal so other scripts can listen to it
	return tween.finished
