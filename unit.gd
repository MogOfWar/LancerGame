class_name Unit
extends Node3D

var hp_: int = 10
var structure_: int = 4
var evasion_: int = 5
var location_grid_: Vector2i = Vector2i(-5,-5)
var location_set_: bool = false
var terrain_: TerrainGrid
var abilities_ = []
var initalized_: bool = false
var targeting_: bool = false
@export var ui_manager_: CanvasLayer
@export var health_bar_scene: PackedScene
@export var chassis: MechChassis
var ui_widgets = {}
var move_points: int = 0
var quick_actions: int = 2
var full_actions: int = 1
var mounts_: Dictionary[MechChassis.MountType, MountPoint] = {}
var mech_type_: MechChassis = null
var curr_select_weapon_: WeaponInstance = null

class MountPoint:
	func _init(type, num):
		type_ = type
		num_ = num
	
	func add_weapon(wp: WeaponType):
		if len(weapons_) < num_:
			weapons_.append(wp)
		else:
			print("Too many weapons naughty boy")
			
	func get_weapon_instance(index: int) -> Unit.WeaponInstance:
		return WeaponInstance.new(weapons_[index], type_)
			
	var type_: MechChassis.MountType = MechChassis.MountType.UNDEFINED
	var num_: int = 0
	var weapons_: Array[WeaponType] = []
	
class WeaponInstance:
	var weapon_: WeaponType
	var mount_: MechChassis.MountType
	
	func _init(w: WeaponType, m: MechChassis.MountType):
		weapon_ = w
		mount_ = m
	
	func get_ui_string() -> String:
		var text = "mount%s \n weapon: %s" % [MechChassis.get_mount_type_name(mount_), weapon_.weapon_name_]
		return text
		
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("building Unit")
	
	pass # Replace with function body.

func get_actions() -> Array[int]:
	return [full_actions, quick_actions]

func get_position_in_world():
	return position

func load_mech_type(mech_type: MechChassis) -> void:
	mech_type_ = mech_type
	hp_ = mech_type.max_hp_
	evasion_ = mech_type.evasion_
	move_points = mech_type.speed_
	
	#for mount in mech_type.mounts_:
	#	if mount.mount_type in mounts_.keys():
	#		print("Error adding already existing mount")
	#	else:
	#		mounts_[mount.mount_type] = MountPoint.new(mount.mount_type, mount.count)

func initalize(loc: Vector2i, terr: TerrainGrid, mech_type: MechChassis) -> void:
	terrain_ = terr
	var y_height = terrain_.get_y_height(loc)
	set_location(loc, y_height)
	SignalBus.unit_spawned.emit(self)
	load_mech_type(mech_type)

func register_health_bar(health_bar) -> void:
	ui_widgets["health_bar"] = health_bar

func add_weapon(gun: WeaponType, mount: MechChassis.MountType ):
	var valid_mounts = mech_type_.mounts_.filter(func(x): return x.mount_type == mount and x.count > 0 )
	if len(valid_mounts) == 0:
		print("Cant add gun no valid mount")
		return
	if len(valid_mounts) > 1:
		print("invalid mech config")
		return
	var mount_data = valid_mounts[0]
	if mount not in mounts_.keys():
		mounts_[mount_data.mount_type] = MountPoint.new(mount_data.mount_type, mount_data.count)
	var mount_to_add: MountPoint = mounts_[mount_data.mount_type]
	mount_to_add.add_weapon(gun)
		

func get_mounts():
	var ret = []
	for mount in mounts_.values():
		for i in range(mount.num_):
			var weapon_ui = mount.get_weapon_instance(i)
			ret.append(weapon_ui)
	return ret

func quick_action_prolouge() -> void:
	pass

func quick_action_epilog() -> void:
	quick_actions = max(quick_actions - 1, 0)
	full_actions = max(full_actions - 1, 0)

func quick_attack(target: Unit) -> int:
	quick_action_prolouge()
	var gun: WeaponType = curr_select_weapon_.weapon_
	var projectile = gun.weapon_scene.instantiate()
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
	var damage: int = gun.roll_damage()
	target.apply_damage(damage)
	projectile.impact()
	
	# 7. clear targeting
	targeting_ = false
	
	# 8. use action points
	quick_action_epilog()
	return damage

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
	
func prepare_attack(w: WeaponInstance):
	targeting_ = true
	curr_select_weapon_ = w
	
func prepare_move():
	pass

func _exit_tree():
	# Important: Tell the manager to delete the UI when this unit is destroyed    
	SignalBus.unit_died.emit(self)
	
	
