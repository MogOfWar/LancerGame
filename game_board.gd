extends Node
class_name GameBoard

class HexData:
	var unit: UnitData
		
class TargetState:
	var weapon_: WeaponType = null
	var origin_pos_: Vector3 # position in world coords
	var targeting_: bool = false
	
	func get_target_mode() -> WeaponType.TargetMode:
		return weapon_.target_mode_
		
	func get_radius() -> int:
		return weapon_.target_mode_radius_
	
	func get_origin_pos() -> Vector3:
		return origin_pos_

@onready var grid_width: int = 0
@onready var grid_height: int = 0

var floating_text_scene_ = preload("res://floating_text.tscn")
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

func get_affected_hexes(center_hex: Vector2i, target_state: TargetState) -> Array[Vector2i]:
	var affected_hexes: Array[Vector2i]
	if target_state.get_target_mode() == WeaponType.TargetMode.Blast:
		affected_hexes = HexUtils.get_blast_hexes(center_hex, target_state.get_radius())
	elif target_state.get_target_mode() == WeaponType.TargetMode.Line:
		var origin_hex: Vector2i = HexUtils.world_to_axial(target_state.get_origin_pos())
		var axial_dist: int = HexUtils.get_axial_distance(origin_hex, center_hex)
		var nudge := Vector2(1e-6, 1e-6)
		var float_origin: Vector2 = Vector2(origin_hex) + nudge
		var float_end: Vector2 = Vector2(center_hex) + nudge
		var step: float = 1.0 / axial_dist
		for i in range(target_state.get_radius()):
			var t = i * step
			var pos = float_origin.lerp(float_end, t)
			affected_hexes.append(HexUtils.cube_round(pos.x, pos.y))
	elif target_state.get_target_mode() == WeaponType.TargetMode.Cone:
		var origin_hex: Vector2i = HexUtils.world_to_axial(target_state.get_origin_pos())
		affected_hexes = HexUtils.get_hexes_in_custom_cone(origin_hex, center_hex, target_state.get_radius(), 60) 
	return affected_hexes

func initalize(grid: GridData):
	grid_ = grid
	grid_width = grid.width_
	grid_height = grid.height_
	#var ass_rifle = load("res://assualt_rifle.tres")
	#a.add_weapon(ass_rifle, MechChassis.MountType.HEAVY)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	SignalBus.end_turn.connect(_on_end_turn)
	
	
func move_unit(unit: UnitData, target_hex: Vector2i):
	var move_path = get_move_path(unit.get_pos_qr(), target_hex)
	for hex_qr in move_path:
		if hex_qr == unit.get_pos_qr():
			continue
		else:
			units.erase(unit.get_pos_qr())
			unit.move(Vector3(hex_qr.x, hex_qr.y, grid_.get_height_from_qr(hex_qr)), 1)
			units[hex_qr] = unit

"""
func _on_hex_hovered(hovered_hex: Vector2i) -> void:
	# If off-map or not targeting, clear all highlights
	if hovered_hex == Vector2i(-9999, -9999):
		SignalBus.ui_draw_highlights.emit([])
		return
		
	var affected_hexes: Array[Vector2i] = [hovered_hex]
	
	if current_state == State.PLAYER_TARGETING:
		if current_target_mode_.targeting_:
			affected_hexes = get_affected_hexes(hovered_hex, current_target_mode_)
	
	var draw_hexes: Array[Vector3] = []

	for x in affected_hexes:
		var local_pos: Vector3 = convert_hex_to_terrain_coords(x)
		draw_hexes.append(local_pos)
	
	SignalBus.ui_draw_highlights.emit(draw_hexes)	

func convert_hex_to_terrain_coords(hex: Vector2i) -> Vector3:
	var global_pos: Vector3 = HexUtils.axial_to_world(hex)
	global_pos.y = terrain.get_y_height(Vector2i(hex)) + 0.05
	return terrain.to_local(global_pos)
"""
func get_move_path(start_world_pos: Vector2i, end_world_pos: Vector2i) -> Array[Vector2i]:
	var dist: int = HexUtils.get_axial_distance(start_world_pos, end_world_pos)
	var path: Array[Vector2i] = []
	var nudge := Vector2(1e-6, 1e-6)
	var float_origin: Vector2 = Vector2(start_world_pos) + nudge
	var float_end: Vector2 = Vector2(end_world_pos) + nudge
	var t: float = 1.0/dist
	for i in range(0,dist+1): #add +1 so we get full lerped
		var float_pos: Vector2 = float_origin.lerp(float_end, i * t)
		var lerped_hex: Vector2i = HexUtils.cube_round(float_pos.x, float_pos.y)
	
		#path.append(convert_hex_to_terrain_coords(lerped_hex))
		path.append(lerped_hex)
	return path

"""func get_unit_move_path(unit: Unit, target_hex: Vector2i) -> Array[Vector2i]:
	var unit_world_pos: Vector3 = unit.get_position_in_world()
	var unit_axial_pos = HexUtils.world_to_axial(unit_world_pos)
	var dist: int = HexUtils.get_axial_distance(target_hex, unit_axial_pos)
	if dist <= unit.get_movement():
		var path: Array[Vector2i] = get_move_path(unit_axial_pos, target_hex, dist)
		if len(path) <= unit.get_movement():
			return path
	return []
"""
"""
func _on_unit_weapon_selected(unit: Unit, weapon: WeaponType) -> void:
	current_target_mode_.weapon_ = weapon
	current_target_mode_.origin_pos_ = unit.get_position_in_world()
	current_target_mode_.targeting_ = true
	current_state = State.PLAYER_TARGETING
"""

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
	
	
	
