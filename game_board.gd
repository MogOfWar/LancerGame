extends Node
class_name GameBoard

class HexData:
	var unit: UnitData = null

var grid_ : GridData
var units: Dictionary[Vector2i, UnitData] = {}
var mech_types_ = {}

var current_player: int = 0

func get_hex_data(hex: Vector2i) -> HexData:
	var ret: HexData = HexData.new()
	if hex in units.keys():
		ret.unit = units[hex]
	return ret
		

func add_unit(unit_data: UnitData) -> void:
	for ocp in HexUtils.get_occupied_hexes(unit_data.get_pos_qr(), unit_data.get_size()):
		units[ocp] = unit_data

func roll_attack(attacking_unit: UnitData, defending_unit: UnitData, accuracy: int) -> Vector2i:
	var attack_roll: int = randi_range(1, 20) 
	var acc_val: int = 0
	for i in range(abs(accuracy)):
		acc_val = max(acc_val, randi_range(1,6))
	acc_val = sign(accuracy) * acc_val
	return Vector2i(attack_roll, acc_val)

func is_ability_executable(unit: UnitData, ability: Ability) -> bool:
	var action_point = unit.get_action_points(ability.action_type_) 
	if action_point == 0:
		return false
	if ability.charges_ <= 0:
		return false
	return true
		

func damage_unit(unit: UnitData, damage_val: int, is_crit: bool) -> void:
	var modified_damage: int = damage_val
	for cond in unit.conditions_:
		if cond.type_ == StatusCondition.StatusConditionType.DAMAGE_RESISTANCE:
			modified_damage *= 0.5		
	unit.hp_ -= modified_damage
	if unit.hp_ > 0:
		SignalBus.unit_damaged.emit(unit, modified_damage)
	if unit.hp_ <= 0:
		SignalBus.unit_died.emit(unit)

func unit_finished_ability(unit: UnitData, ability: Ability) -> void:
	match ability.action_type_:
		Ability.ActionType.MOVEMENT:
			ability.charges_ = unit.get_movement_points()
		Ability.ActionType.QUICK_ACTION:
			ability.charges_ -= 1
	unit.finished_ability(ability)

func get_affected_hexes(center_hex: Vector2i, effect: Effect, origin_hex: Vector2i) -> Array[Vector2i]:
	var affected_hexes: Array[Vector2i]
	if effect.target_mode_ == Effect.TargetMode.Single:
		affected_hexes = [center_hex]
	elif effect.target_mode_ == Effect.TargetMode.Blast:
		affected_hexes = HexUtils.get_blast_hexes(center_hex, effect.target_mode_radius_)
	elif effect.target_mode_ == Effect.TargetMode.Line:
		affected_hexes = HexUtils.stride_lerp(origin_hex, center_hex, effect.target_mode_radius_)
	elif effect.target_mode_ == Effect.TargetMode.Cone:
		affected_hexes = HexUtils.get_hexes_in_custom_cone(origin_hex, center_hex, effect.target_mode_radius_, 60) 
	return affected_hexes.filter(func(x): return grid_.check_hex_in_grid(x))

func initalize(grid: GridData):
	grid_ = grid

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

func update_unit_location(unit:UnitData, new_location: Vector3):
	var occupied_hexes: Array[Vector2i] = HexUtils.get_occupied_hexes(unit.get_pos_qr(), unit.get_size())
	for ocp_hex: Vector2i in occupied_hexes:
		units.erase(ocp_hex)
	unit.move(new_location, 1)
	add_unit(unit)

func get_move_path(moving_unit: UnitData, start_pos_qr: Vector2i, end_pos_qr: Vector2i) -> Array[Vector2i]:
	var temporarily_solid_hexes: Array[int] = []
	for other_unit: UnitData in units.values():
		if other_unit == moving_unit:
			continue
		for ocp in HexUtils.get_occupied_hexes(other_unit.get_pos_qr(), other_unit.get_size()):
			var hex_index: int = grid_.get_grid_index(ocp)
			grid_.astar_.set_point_disabled(hex_index, true)
			temporarily_solid_hexes.append(hex_index) # Track it!
	
	var path = grid_.astar_.get_id_path(grid_.get_grid_index(start_pos_qr), grid_.get_grid_index(end_pos_qr))
	
	#resotre 
	for t in temporarily_solid_hexes:
		grid_.astar_.set_point_disabled(t, false)
		
	var ret: Array[Vector2i]
	for p in path:
		ret.append(grid_.get_position(p))
	return ret
	

# function that returns all hex in axial coordinates that can be reached from source_hex in < range movement points
func get_movement_range(source_hex: Vector2i, mv_range: int, unit_size: int) -> Array[Vector2i]:
	var source_index: int = grid_.get_grid_index(source_hex)
	var frontier: Array[int] = [source_index]
	var reachable: Dictionary[int, int] = {source_index : mv_range}
	while not frontier.is_empty():
		var current_hex_index = frontier.pop_front()
		var current_mp = reachable[current_hex_index]
		for neighbour in grid_.get_neighbours(current_hex_index):
			# cant move through any units
			var pos_qr = grid_.get_position(neighbour)
			var neighbour_ok: bool = true
			for ocp in HexUtils.get_occupied_hexes(pos_qr, unit_size):
				if ocp == source_hex:
					#source hex will contain this unit and will break on next if
					continue 
				if units.has(ocp) or not grid_.check_hex_in_grid(ocp):
					neighbour_ok = false
			if not neighbour_ok:
				continue
			var cost = grid_.get_cost(neighbour)
			var next_mp = current_mp - cost
			
			if next_mp >= 0:
				if not reachable.has(neighbour) or next_mp > reachable[neighbour]:
					reachable[neighbour] = next_mp
					frontier.append(neighbour)
	
	var ret: Array[Vector2i]
	ret.resize(len(reachable.keys()))
	for i in range(len(reachable.keys())):
		ret[i] = grid_.get_position(reachable.keys()[i])
	return ret

# this function can be optimized thus a bunch of redundent math
func get_hexes_qr_in_range(source_hex_qr: Vector2i, ab_range: int) -> Array[Vector2i]:
	var hexes_in_range = HexUtils.get_hexes_in_range(source_hex_qr, ab_range)
	var ret: Array[Vector2i] = []
	for hex in hexes_in_range:
		if grid_.check_hex_in_grid(hex):
			ret.append(hex)
		#var path = HexUtils.stride_lerp(source_hex_qr, hex)
		# check los here
	return ret
	
func get_units_in_range(source_hex_qr: Vector2i, ab_range: int) -> Array[Vector2i]:
	var ret : Array[Vector2i] = []
	for unit_pos_qr in units.keys():
		var dist: int = HexUtils.get_axial_distance(source_hex_qr, unit_pos_qr)
		if dist <= ab_range and dist > 0:
			ret.append(unit_pos_qr)
			#also check los
	return ret

func state_apply_status_condition(condition: StatusCondition, unit: UnitData):
	unit.apply_condition(condition)
	
	
