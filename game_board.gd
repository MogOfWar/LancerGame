extends Node
class_name GameBoard

class HexData:
	var units: Array[UnitData] = []
	var terrain_effects: Array[TerrainEffect.TerrainHazzard] = []
	var terrain_tag: int
	
enum LOSResult {
	CLEAR,
	BLOCKED,
	HARD_COVER,
	SOFT_COVER
}

var grid_ : GridData
var hexes_: Dictionary[Vector2i, HexData]
var units: Dictionary[UnitData, Array] = {}


func get_selectable_unit(hex: Vector2i) -> UnitData:
	var hex_data: HexData = get_hex_data(hex)
	if hex_data.units.is_empty():
		return null
	else:
		# for now only one unit can be per hex layer we will check some other critira
		return hex_data.units[0]

func get_hex_data(hex: Vector2i) -> HexData:
	return hexes_.get(hex, HexData.new())

func calculate_terrain_mask(hazzards: Array) -> int:
	var ret_mask = 0
	for hzzrd : TerrainEffect.TerrainHazzard in hazzards:
		ret_mask |= hzzrd.terrain_effect_type_
	return ret_mask
	
func add_terrain_effect(hex_qr: Vector2i, terrain_eff: TerrainEffect.TerrainHazzard) -> void:
	var hex_data: HexData = hexes_.get_or_add(hex_qr, HexData.new())
	hex_data.terrain_effects.append(terrain_eff)
	hex_data.terrain_tag = calculate_terrain_mask(hex_data.terrain_effects)
	
func add_unit(unit_data: UnitData) -> void:
	if units.has(unit_data):
		Utils.log_error("Adding existing unit")
		return
	units[unit_data] = []
	for ocp in HexUtils.get_occupied_hexes(unit_data.get_pos_qr(), unit_data.get_size()):
		var hex_data = hexes_.get_or_add(ocp, HexData.new())
		hex_data.units.append(unit_data)

func roll_attack(attacking_unit: UnitData, defending_unit: UnitData, accuracy: int) -> Vector2i:
	var attack_roll: int = randi_range(1, 20) 
	var acc_val: int = 0
	for i in range(abs(accuracy)):
		acc_val = max(acc_val, randi_range(1,6))
	acc_val = sign(accuracy) * acc_val
	return Vector2i(attack_roll, acc_val)

func is_ability_executable(unit: UnitData, ability: Ability) -> bool:
	if ability.charges_ <= 0:
		return false
	match ability.action_type_:
		Ability.ActionType.QUICK_ACTION:
			return unit.action_budget_ >= 1
		Ability.ActionType.FULL_ACTION:
			return unit.action_budget_ >= 2
		Ability.ActionType.MOVEMENT:
			return unit.current_movement_ > 0
		Ability.ActionType.REACTION:
			return true # Evaluated against reaction triggers/round limits
	return false
		

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
		Ability.ActionType.FULL_ACTION:
			ability.charges_ -= 1
		Ability.ActionType.REACTION:
			ability.charges_ -= 1
	unit.finished_ability(ability)

func start_round() -> void:
	for unit: UnitData in units.keys():
		unit.refresh_abilties(Ability.RefreshPolicy.ON_ROUND_START)

func start_turn(current_player: PlayerController) -> void:
	for unit: UnitData in units.keys():
		if unit.own_player_id_ == current_player.player_id_:
			unit.refresh_action_points()
			unit.refresh_abilties(Ability.RefreshPolicy.ON_TURN_START)

func end_turn(current_player: PlayerController) -> void:
	for unit: UnitData in units.keys():
		if unit.own_player_id_ == current_player.player_id_:
			unit.tick_status_conditions(Ability.RefreshPolicy.ON_TURN_END)

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
	var cover_hazzard: TerrainEffect.TerrainHazzard = TerrainEffect.TerrainHazzard.new(-1, TerrainEffect.TerrainEffectType.SOFT_COVER)
	for y in range(grid_.height_):
		for x in range(grid_.width_):
			var cell = grid_.get_cell_from_cr(x, y)
			if cell.type == "Forest":
				var hex_qr: Vector2i = HexUtils.arr_idx_to_axial(x, y)
				add_terrain_effect(hex_qr, cover_hazzard)
		
	
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

func remove_unit(unit: UnitData):
	if not units.has(unit):
		Utils.log_error("removing non existing unit")
	units.erase(unit)
	var occupied_hexes: Array[Vector2i] = HexUtils.get_occupied_hexes(unit.get_pos_qr(), unit.get_size())
	for ocp_hex: Vector2i in occupied_hexes:
		if not hexes_.has(ocp_hex):
			Utils.log_error("Trying to remove unit which wasn't registered")
		var hex_data: HexData = hexes_.get(ocp_hex)
		if not hex_data.units.has(unit):
			Utils.log_error("Trying to remove unit which wasn't registered")
		else:
			hex_data.units.erase(unit)
		
func update_unit_location(unit:UnitData, new_location: Vector3):
	remove_unit(unit)
	unit.move(new_location, 1)
	add_unit(unit)

func get_move_path(moving_unit: UnitData, start_pos_qr: Vector2i, end_pos_qr: Vector2i) -> Array[Vector2i]:
	var temporarily_solid_hexes: Array[int] = []
	for other_unit: UnitData in units.keys():
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
	for unit: UnitData in units.keys():
		var unit_pos_qr: Vector2i = unit.get_pos_qr()
		var dist: int = HexUtils.get_axial_distance(source_hex_qr, unit_pos_qr)
		if dist <= ab_range and dist > 0:
			ret.append(unit_pos_qr)
			#also check los
	return ret

func state_apply_status_condition(condition: StatusCondition, unit: UnitData):
	unit.apply_condition(condition)
	
func calculate_los(src_qr: Vector2i, target_qr: Vector2i) -> LOSResult:
	var path := HexUtils.stride_lerp(src_qr, target_qr, 1000)
	var ret: int = -1
	for hex in path:
		if hex in hexes_.keys():
			var terrain_mask: int = get_hex_data(hex).terrain_tag
			if (terrain_mask & TerrainEffect.TerrainEffectType.SOFT_COVER) != 0:
				ret = max(ret, TerrainEffect.TerrainEffectType.SOFT_COVER)
			if (terrain_mask & TerrainEffect.TerrainEffectType.HARD_COVER) != 0:
				ret = max(ret, TerrainEffect.TerrainEffectType.HARD_COVER)
			if (terrain_mask & TerrainEffect.TerrainEffectType.LOS_BLOCK) != 0:
				ret = max(ret, TerrainEffect.TerrainEffectType.LOS_BLOCK)
		
	if ret == TerrainEffect.TerrainEffectType.SOFT_COVER:
		return LOSResult.SOFT_COVER
	elif ret == TerrainEffect.TerrainEffectType.HARD_COVER:
		return LOSResult.HARD_COVER
	elif ret == TerrainEffect.TerrainEffectType.LOS_BLOCK:
		return LOSResult.BLOCKED
	return LOSResult.CLEAR
	
