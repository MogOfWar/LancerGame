extends Node

var floating_text_scene_: PackedScene = preload(Constants.VFX_PATH + "//floating_text.tscn")
var weapon_porjectile_: GPUParticles3D = preload("res://vfx/machine_gun_tracers.tscn").instantiate()
# Called when the node enters the scene tree for the first time.

func _ready() -> void:
	add_child(weapon_porjectile_)

### params dictionary
### text_to_show
### global_position
func spawn_text(params: Dictionary) -> Signal:
	var float_text = floating_text_scene_.instantiate()
	add_child(float_text)
	return float_text.display(params["text_to_show"], params["global_position"], true)

func spawn_projectile(unit: Unit, target: Vector3):
	weapon_porjectile_.global_position = unit.get_weapon_global_pos()
	await weapon_porjectile_.shoot(target)
	
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
