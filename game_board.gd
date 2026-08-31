extends Node
class_name GameBoard

class HexData:
	var unit: UnitData = null

@onready var grid_width: int = 0
@onready var grid_height: int = 0

var floating_text_scene_ = preload(Constants.VFX_PATH + "//floating_text.tscn")
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
	units[unit_data.get_pos_qr()] = unit_data

func roll_attack(attacking_unit: UnitData, defending_unit: UnitData, accuracy: int) -> bool:
	var attack_roll: int = randi_range(1, 20) 
	var acc_val: int = 0
	for i in range(abs(accuracy)):
		acc_val = max(acc_val, randi_range(1,6))
	attack_roll += sign(accuracy) * acc_val
	var hit: bool = attack_roll > 10 or true
	SignalBus.unit_attacking.emit(attacking_unit, hit)
	return hit

func is_ability_executable(unit: UnitData, ability: Ability) -> bool:
	var action_point = unit.get_action_points(ability.action_type_) 
	if action_point == 0:
		return false
	if ability.charges_ <= 0:
		return false
	return true
		

func damage_unit(unit: UnitData, damage_val: int) -> void:
	unit.hp_ -= damage_val
	if unit.hp_ > 0:
		SignalBus.unit_damaged.emit(unit, damage_val)
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
	grid_width = grid.width_
	grid_height = grid.height_

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	SignalBus.end_turn.connect(_on_end_turn)
	
func move_unit(unit: UnitData, target_hex: Vector2i) -> int:
	var move_path = get_move_path(unit, unit.get_pos_qr(), target_hex)
	var hexes_moved: int = 0
	for hex_qr in move_path:
		if hex_qr == unit.get_pos_qr():
			continue
		else:
			units.erase(unit.get_pos_qr())
			unit.move(Vector3(hex_qr.x, hex_qr.y, grid_.get_height_from_qr(hex_qr)), 1)
			units[hex_qr] = unit
			hexes_moved += 1
	return hexes_moved

func get_move_path(moving_unit: UnitData, start_pos_qr: Vector2i, end_pos_qr: Vector2i) -> Array[Vector2i]:
	var temporarily_solid_hexes: Array[int] = []
	for other_unit: UnitData in units.values():
		if other_unit == moving_unit:
			continue
		var hex_index: int = grid_.get_grid_index(other_unit.get_pos_qr())
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

func _on_end_turn() -> void:
	pass
	#current_selected_unit = null
	#current_player += 1
	#if (current_player) == num_players:
	#	end_round()
	
func end_round() -> void:
	current_player = 0

# function that returns all hex in axial coordinates that can be reached from source_hex in < range movement points
func get_movement_range(source_hex: Vector2i, range: int) -> Array[Vector2i]:
	var source_index: int = grid_.get_grid_index(source_hex)
	var frontier: Array[int] = [source_index]
	var reachable: Dictionary[int, int] = {source_index : range}
	while not frontier.is_empty():
		var current_hex_index = frontier.pop_front()
		var current_mp = reachable[current_hex_index]
		for neighbour in grid_.get_neighbours(current_hex_index):
			# cant move through any units
			if units.has(grid_.get_position(neighbour)):
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
func get_hexes_qr_in_range(source_hex_qr: Vector2i, range: int) -> Array[Vector2i]:
	var hexes_in_range = HexUtils.get_hexes_in_range(source_hex_qr, range)
	var ret: Array[Vector2i] = []
	for hex in hexes_in_range:
		if grid_.check_hex_in_grid(hex):
			ret.append(hex)
		#var path = HexUtils.stride_lerp(source_hex_qr, hex)
		# check los here
	return ret
	
func get_units_in_range(source_hex_qr: Vector2i, range: int) -> Array[Vector2i]:
	var ret : Array[Vector2i] = []
	for unit_pos_qr in units.keys():
		var dist: int = HexUtils.get_axial_distance(source_hex_qr, unit_pos_qr)
		if dist < range and dist > 0:
			ret.append(unit_pos_qr)
			#also check los
	return ret
	
	
	
