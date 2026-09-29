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
			Utils.log_error("Too many weapons naughty boy")
			
	func get_weapon_instance(index: int) -> UnitData.WeaponInstance:
		return WeaponInstance.new(weapons_[index], type_, index)
			
	var type_: MechChassis.MountType = MechChassis.MountType.UNDEFINED
	var num_: int = 0
	var weapons_: Array[WeaponType] = []
	
class WeaponInstance:
	var weapon_: WeaponType
	var mount_: MechChassis.MountType
	var index_: int = 0
	
	func _init(w: WeaponType, m: MechChassis.MountType, index: int):
		weapon_ = w
		mount_ = m
		index_ = index
	
	func get_ui_string() -> String:
		var text = "mount%s:%s \n weapon: %s" % [MechChassis.get_mount_type_name(mount_), index_, weapon_.weapon_name_]
		return text

var unit_id_: int = -1:
	get:
		return unit_id_
		
		
var abilities_: Array[Ability] = []
var hp_: int = 10
var structure_: int = 4
var evasion_: int = 5
var action_points_: Array[int]
var mounts_: Dictionary[MechChassis.MountType, MountPoint] = {}
var mech_type_: MechChassis = null
var curr_select_weapon_: WeaponInstance = null
var pos_qr_: Vector2i
var height_: float
var own_player_id_: int = -1
var conditions_: Array[StatusCondition] = []


@export var chassis: MechChassis

signal unit_selected()
signal unit_deselected()
signal unit_moved(source_qry: Vector3, target_qry: Vector3)

class IdGenerator:
	static var _counter: int = 0
	static var _mutex: Mutex = Mutex.new()
	
	static func get_next_id() -> int:
		_mutex.lock()
		var id = _counter
		_counter += 1
		_mutex.unlock()
		return id

func refresh_action_points() -> void:
	action_points_[Ability.ActionType.QUICK_ACTION] = 2
	action_points_[Ability.ActionType.FULL_ACTION] = 1
	action_points_[Ability.ActionType.MOVEMENT] = 1000

func add_ability(ability: Ability) -> void:
	ability.id_ = len(abilities_)
	abilities_.append(ability)
	SignalBus.unit_gained_ability.emit(self, ability)

func get_ability_by_id(id: int) -> Ability:
	if id < 0 or id > len(abilities_):
		Utils.log_error("invalid ability id")
		return null
	return abilities_[id]

func _init(mech_type: MechChassis, pos_qr: Vector2i, height: float, player: PlayerController) -> void:
	#first connect signals
	SignalBus.start_round.connect(_on_start_round)
	
	#setup data mebers
	unit_id_ = IdGenerator.get_next_id()
	own_player_id_ = player.player_id_
	pos_qr_ = pos_qr
	height_ = height
	load_mech_type(mech_type)
	action_points_.resize(Ability.ActionType.NUM_ACTION_TYPES)
	refresh_action_points()
	
	#add abilties
	add_ability(MoveAbility.new(0))
	add_ability(SkirimishAbility.new(1, self))
	add_ability(BraceAbility.new(2))
	add_ability(OverwatchAbility.new(3, self))

func _on_start_round(round_number: int) -> void:
	refresh_action_points()
	for ability: Ability in abilities_:
		if ability.refresh_policy_ == Ability.RefreshPolicy.ON_TURN_START:
			ability.refresh()

func get_pos_qry() -> Vector3:
	return Vector3(pos_qr_.x, pos_qr_.y, height_)

func get_pos_qr() -> Vector2i:
	return pos_qr_

func get_ability_list() -> Array[Ability]:
	return abilities_
	
func get_evasion() -> int:
	return evasion_
	
func get_movement_points() -> int:
	return get_action_points(Ability.ActionType.MOVEMENT)

func get_defense_accuracy() -> int:
	var ret: int = 0
	for cond : StatusCondition in conditions_:
		if cond.is_triggered_for_defense():
			ret += cond.acc_modifer_
	return ret
	
func get_attack_accuracy() -> int:
	var ret: int = 0
	for cond : StatusCondition in conditions_:
		if cond.is_triggered_for_attack():
			ret += cond.acc_modifer_
	return ret

func get_attack_override() -> bool:
	return false

func get_defense_override() -> bool:
	return false
	
func select():
	unit_selected.emit()

func deselect():
	unit_deselected.emit()
	
func apply_condition(condition):
	conditions_.append(condition)
	
func get_size():
	return mech_type_.size_
	
func finished_ability(ability: Ability):
	if ability.action_type_ == Ability.ActionType.QUICK_ACTION:
		action_points_[Ability.ActionType.QUICK_ACTION] -= 1
		action_points_[Ability.ActionType.FULL_ACTION] -= 1
	elif ability.action_type_ == Ability.ActionType.FULL_ACTION:
		action_points_[Ability.ActionType.QUICK_ACTION] = 0
		action_points_[Ability.ActionType.FULL_ACTION] -= 1
		
		
func move(dest_hex_qry: Vector3, dist: int):
	
	if action_points_[Ability.ActionType.MOVEMENT] - dist < 0:
		Utils.log_error("Moved more units than allowed %s %s %s" % [self.unit_id_, pos_qr_, dist])
	action_points_[Ability.ActionType.MOVEMENT] -= dist
	var source_qry: Vector3 = Vector3(pos_qr_.x, pos_qr_.y, height_)
	pos_qr_ = Vector2i(dest_hex_qry.x, dest_hex_qry.y)
	height_ = dest_hex_qry.z
	SignalBus.unit_moved.emit(self, source_qry, dest_hex_qry)

func load_mech_type(mech_type: MechChassis) -> void:
	mech_type_ = mech_type
	hp_ = mech_type.max_hp_
	evasion_ = mech_type.evasion_
	
func add_weapon(gun: WeaponType, mount: MechChassis.MountType ):
	if not gun:
		Utils.log_error("invalid gun")
		return
	var valid_mounts = mech_type_.mounts_.filter(func(x): return x.mount_type == mount and x.count > 0 )
	if len(valid_mounts) == 0:
		Utils.log_error("Cant add gun no valid mount")
		return
	if len(valid_mounts) > 1:
		Utils.log_error("invalid mech config")
		return
	var mount_data = valid_mounts[0]
	if mount not in mounts_.keys():
		mounts_[mount_data.mount_type] = MountPoint.new(mount_data.mount_type, mount_data.count)
	var mount_to_add: MountPoint = mounts_[mount_data.mount_type]
	mount_to_add.add_weapon(gun)
	
	# update abilities with new weapon
	for ability in abilities_:
		if ability.ability_name_ == SkirimishAbility.NAME:
			(ability as SkirimishAbility).update_effect_list()
		elif ability.ability_name_ == OverwatchAbility.NAME:
			var ow: OverwatchAbility = ability as OverwatchAbility
			ow.update_effect_list()
			# need to update reaction 
			var reaction: ReactionManager.Reaction = ow.get_reaction()
			if reaction:
				var type = ow.get_reaction_type()
				var player: PlayerController = Level.get_current_level().turn_manager_.get_player_by_id(own_player_id_)
				Level.get_current_level().reaction_manager_.register_reaction(type, self, player, reaction)
				
func get_mounts() -> Array[WeaponInstance]:
	var ret: Array[WeaponInstance] = []
	for mount in mounts_.values():
		for i in range(mount.num_):
			var weapon: WeaponInstance = mount.get_weapon_instance(i)
			ret.append(weapon)
	return ret
	
func get_action_points(action_type: Ability.ActionType) -> int:
	return action_points_[action_type]
