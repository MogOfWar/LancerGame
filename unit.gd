class_name Unit
extends Node3D

var hp_: int = 10
var structure_: int = 5
var evasion_: int = 5
var location_grid_: Vector2i = Vector2i(-5,-5)
var location_set_: bool = false
var terrain_: TerrainGrid
var abilities_ = []
var initalized_: bool = false
var targeting_: bool = false
@export var ui_manager_: CanvasLayer
@export var health_bar_scene: PackedScene
var ui_widgets = {}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("building Unit")
	
	pass # Replace with function body.

func initalize(loc: Vector2i, terr: TerrainGrid, ui_manager: CanvasLayer) -> void:
	terrain_ = terr
	var y_height = terrain_.get_y_height(loc)
	set_location(loc, y_height)
	ui_manager_ = ui_manager
	ui_widgets["health_bar"] = (ui_manager.register_unit(self,health_bar_scene))
	ui_widgets["health_bar"].setup(hp_)

func add_ability(ability: Ability):
	abilities_.append(ability)

func set_location(loc: Vector2i, y: float) -> void:
	location_grid_ = loc
	location_set_ = true
	position = HexUtils.axial_to_world(loc)
	position.y = y

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func select():
	$SelectionRing.visible = true

func deselect():
	$SelectionRing.visible = false
	
func apply_damage(damage: int) -> void:
	hp_ -= damage
	hp_ = max(hp_, 0)
	if hp_ > 0:
		ui_widgets["health_bar"].update_health(hp_)
		
func move(new_loc: Vector2i) -> void:
	var y_height = terrain_.get_y_height(new_loc)
	set_location(new_loc, y_height)
	
func activate_ability(target: Unit, ability_index):
	var ability: Ability = abilities_[ability_index]
	var projectile = ability.ability_scene.instantiate()
	get_tree().current_scene.add_child(projectile)
	var spawn_offset := Vector3(0, 1.5, 0) # Raise spawn point so it doesn't clip into the floor
	projectile.global_position = global_position + spawn_offset
	
	# 2. Aim at the target
	# In 3D, look_at requires a target position and an "Up" vector to know which way is top
	var target_center = target.global_position + spawn_offset
	projectile.look_at(target_center, Vector3.UP)

	# 3. Create the Tween
	var tween = create_tween()

	# Optional: Calculate time based on distance for consistent speed
	# var distance = projectile.global_position.distance_to(target_center)
	# var travel_time = distance / 10.0 # 10 units per second
	var travel_time = 0.5 

	# 4. Animate the position to the target
	tween.tween_property(projectile, "global_position", target_center, travel_time).set_trans(Tween.TRANS_LINEAR)

	# 5. Halt execution until the projectile arrives
	await tween.finished

	# 6. Apply damage and clean up
	target.apply_damage(5)
	projectile.impact()
	
	# 7. clear targeting
	targeting_ = false
	
func prepare_attack():
	targeting_ = true
	
func prepare_move():
	pass

func _exit_tree():
	# Important: Tell the manager to delete the UI when this unit is destroyed    
	ui_manager_.unregister_unit(self)
	
	
