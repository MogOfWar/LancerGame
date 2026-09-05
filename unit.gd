class_name Unit
extends Node3D

var targeting_: bool = false
var unit_data_: UnitData

@onready var animation_player_ = $Visuals/AnimationPlayer

func _set_up_animations() -> void:
	var a: Animation = animation_player_.get_animation("mech_library/Idle_south")
	a.loop_mode = Animation.LOOP_LINEAR
	
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	SignalBus.vis_unit_spawned.emit(self)
	unit_data_.unit_selected.connect(select)
	unit_data_.unit_deselected.connect(deselect)
	_set_up_animations()
	play_idle_animation()
	
func initalize(unit_data: UnitData) -> void:
	unit_data_ = unit_data
	set_location(unit_data_.get_pos_qry())

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

func get_animation(direction: Vector3) -> String:
	var anim_name = "mech_ani_library_2/walk_" 
	# 1. Determine if we need to flip horizontally
	if direction.x > 0:
		# Moving Right (East, NE, SE)
		$Visuals/MechSprite.flip_h = false # Flip the entire visual container
	elif direction.x < 0:
		# Moving Left (West, NW, SW)
		$Visuals/MechSprite.flip_h = true  # Face normal

	# 2. Determine the base animation name
	# We round the direction to snap it to pure 8-way angles
	var snapped_dir = Vector2(direction.x, direction.y).snapped(Vector2(1, 1))
	
	if snapped_dir.y < 0:
		if snapped_dir.x == 0:
			anim_name += "n"
		else:
			anim_name += "ne" # Used for both NW and NE (since NE is flipped)
			
	elif snapped_dir.y > 0:
		if snapped_dir.x == 0:
			anim_name += "s"
		else:
			anim_name += "se" # Used for both SW and SE
			
	else:
		anim_name += "e" # Used for both W and E
		
	# 3. Play the animation
	return anim_name

func get_animation2(direction: Vector3, base_anim_name: String):
	const facing_map = ["south", "south-east", "east", "north-east", "north", "north-west", "west", "south-west"]
	var angle = atan2(direction.x, direction.z)
	var facing_dir: int = roundi((angle) * (4 / PI))
	var anim_name: String = "mech_library/%s_%s" % [base_anim_name, facing_map[(facing_dir + 8) % 8]]
	return anim_name
	
func move(src_qry: Vector3, hex_qry: Vector3):
	# 1. Update facing direction based on movement vector	
	var direction = (hex_qry - src_qry)
	var anim_name: String = get_animation2(Vector3(direction.x, direction.z, direction.y), "Walking")
	var anim = animation_player_.get_animation(anim_name)	
	if anim:
		# Set the loop mode to wrap/loop
		anim.loop_mode = Animation.LOOP_LINEAR
	animation_player_.play(anim_name)
	
	var target_pos: Vector3 = HexUtils.axial_to_world(Vector2(hex_qry.x, hex_qry.y))
	target_pos.y = hex_qry.z
	# 2. Tween to the next point (adjust duration per tile as needed)
	var distance = global_position.distance_to(target_pos)
	var duration = distance / 3.0 # Speed factor
		
	var tween = create_tween()
	tween.tween_property(self, "global_position", target_pos, duration)
	await tween.finished
	animation_player_.stop()

func play_attack_animation(tar_global_pos: Vector3) -> void:
	var direction: Vector3 = (tar_global_pos - global_position)
	animation_player_.play(get_animation2(direction, "attacking"))
	
func play_idle_animation() -> void:
	
	animation_player_.play("mech_library/Idle_south")

func get_weapon_global_pos() -> Vector3:
	return $Visuals/MechSprite/MuzzleFire.global_position
	

func _exit_tree():
	# Important: Tell the manager to delete the UI when this unit is destroyed    
	SignalBus.unit_died.emit(self)
	
	
