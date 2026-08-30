extends Node

var floating_text_scene_: PackedScene = preload(Constants.VFX_PATH + "//floating_text.tscn")

# Called when the node enters the scene tree for the first time.

func _ready() -> void:
	pass

### params dictionary
### text_to_show
### global_position
func spawn_text(params: Dictionary) -> Signal:
	var float_text = floating_text_scene_.instantiate()
	add_child(float_text)
	return float_text.display(params["text_to_show"], params["global_position"], true)
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
