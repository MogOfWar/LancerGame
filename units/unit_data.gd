extends RefCounted
class_name UnitData

class MountPoint:
	func _init(type, num):
		type_ = type
		num_ = num
	
	func add_weapon(wp: WeaponType):
		if len(weapons_) < num_:
			weapons_.append(wp)
		else:
			print("Too many weapons naughty boy")
			
	func get_weapon_instance(index: int) -> UnitData.WeaponInstance:
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

var unit_id_: int = -1
var abilities_: Array[Ability] = []
var hp_: int = 10
var structure_: int = 4
var evasion_: int = 5
var move_points: int = 0
var quick_actions: int = 2
var full_actions: int = 1
var mounts_: Dictionary[MechChassis.MountType, MountPoint] = {}
var mech_type_: MechChassis = null
var curr_select_weapon_: WeaponInstance = null
var pos_qr_: Vector2i
var height_: float


@export var chassis: MechChassis

signal unit_selected()
signal unit_deselected()
signal unit_moved(target_qry: Vector3)

class IdGenerator:
	static var _counter: int = 0
	static var _mutex: Mutex = Mutex.new()
	
	static func get_next_id() -> int:
		_mutex.lock()
		var id = _counter
		_counter += 1
		_mutex.unlock()
		return id

func _init(mech_type: MechChassis, pos_qr: Vector2i, height: float) -> void:
	unit_id_ = IdGenerator.get_next_id()
	abilities_.append(MoveAbility.new())
	pos_qr_ = pos_qr
	height_ = height
	load_mech_type(mech_type)

func get_pos_qry() -> Vector3:
	return Vector3(pos_qr_.x, pos_qr_.y, height_)

func get_pos_qr() -> Vector2i:
	return pos_qr_

func get_ability_list() -> Array[Ability]:
	return abilities_
	
func get_movement_points() -> int:
	return move_points

func select():
	unit_selected.emit()

func deselect():
	unit_deselected.emit()
	
func move(hex_qry: Vector3, dist: int):
	
	if move_points - dist < 0:
		Utils.log_error("Moved more units than allowed %s %s %s" % [self.unit_id_, pos_qr_, dist])
	move_points -= dist
	pos_qr_ = Vector2i(hex_qry.x, hex_qry.y)
	height_ = hex_qry.z
	unit_moved.emit(hex_qry)

func load_mech_type(mech_type: MechChassis) -> void:
	mech_type_ = mech_type
	hp_ = mech_type.max_hp_
	evasion_ = mech_type.evasion_
	move_points = mech_type.speed_
	
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
