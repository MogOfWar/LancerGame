class_name Unit
extends Node3D

var targeting_: bool = false
var unit_data_: UnitData
var ui_widgets = {}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("building Unit")
	SignalBus.vis_unit_spawned.emit(self)
	unit_data_.unit_selected.connect(select)
	unit_data_.unit_deselected.connect(deselect)
	unit_data_.unit_moved.connect(_on_move)

func initalize(unit_data: UnitData) -> void:
	unit_data_ = unit_data
	set_location(unit_data_.get_pos_qry())
	
func get_position_in_world():
	return position


func register_health_bar(health_bar) -> void:
	ui_widgets["health_bar"] = health_bar
		

func quick_action_prolouge() -> void:
	pass
	
#func quick_action_epilog() -> void:
#	quick_actions = max(quick_actions - 1, 0)
#	full_actions = max(full_actions - 1, 0)

#func quick_attack(target: Unit) -> int:
#	quick_action_prolouge()
#	var gun: WeaponType = curr_select_weapon_.weapon_
#	var projectile = gun.weapon_scene.instantiate()
#	get_tree().current_scene.add_child(projectile)
#	var spawn_offset := Vector3(0, 1.5, 0) # Raise spawn point so it doesn't clip into the floor
#	projectile.global_position = global_position + spawn_offset
	
	# 2. Aim at the target
	# In 3D, look_at requires a target position and an "Up" vector to know which way is top
#	var target_center = target.global_position + spawn_offset
#	projectile.look_at(target_center, Vector3.UP)

	# 3. Create the Tween
#	var tween = create_tween()

	# Optional: Calculate time based on distance for consistent speed
	# var distance = projectile.global_position.distance_to(target_center)
	# var travel_time = distance / 10.0 # 10 units per second
#	var travel_time = 0.5 

	# 4. Animate the position to the target
#	tween.tween_property(projectile, "global_position", target_center, travel_time).set_trans(Tween.TRANS_LINEAR)

	# 5. Halt execution until the projectile arrives
#	await tween.finished

	# 6. Apply damage and clean up
#	var damage: int = gun.roll_damage()
#	target.apply_damage(damage)
#	projectile.impact()
#	
	# 7. clear targeting
#	targeting_ = false
	
	# 8. use action points
	#quick_action_epilog()
	#return damage

func set_location(pos_qry: Vector3) -> void:
	var loc_qr = Vector2i(pos_qry.x, pos_qry.y)
	var new_pos: Vector3 = HexUtils.axial_to_world(loc_qr)
	new_pos.y = pos_qry.z
	set_position(new_pos)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func select():
	$SelectionRing.visible = true

func deselect():
	$SelectionRing.visible = false
	
#func apply_damage(damage: int) -> void:
#	hp_ -= damage
#	hp_ = max(hp_, 0)
#	if hp_ > 0:
#		ui_widgets["health_bar"].update_health(hp_)
	
func _on_move(hex_qry: Vector3):
	set_location(hex_qry)
	#play animation

func _exit_tree():
	# Important: Tell the manager to delete the UI when this unit is destroyed    
	SignalBus.unit_died.emit(self)
	
	
