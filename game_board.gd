extends Node
class_name GameBoard

const AXIAL_DIRECTIONS: Array[Vector2i] = [
	Vector2i(1, 0),   # Right
	Vector2i(1, -1),  # Top-right
	Vector2i(0, -1),  # Top-left
	Vector2i(-1, 0),  # Left
	Vector2i(-1, 1),  # Bottom-left
	Vector2i(0, 1)    # Bottom-right
]

class HexData:
	var unit: UnitData
	var height: float
	var cost: = 1
	var y: int
	var x: int	
	
class Grid:
	var data_: Array[HexData]
	var width_: int
	var height_: int
	var astar_grid: AStar2D
	
	func _init(w: int, h: int) -> void:
		width_ = w
		height_ = h
		data_.resize(w*h)
		astar_grid = AStar2D.new()
		for y in range(height_):
			for x in range(width_):
				var index: int = y * width_ + x
				var hex_data = HexData.new()
				hex_data.x = x
				hex_data.y = y
				data_[index] = hex_data
				astar_grid.add_point(index, HexUtils.arr_idx_to_axial(x, y), hex_data.cost)
		
		for i in range(len(data_)):
			var hex_data = data_[i]
			var axial_coord = HexUtils.arr_idx_to_axial(hex_data.x, hex_data.y)
			for dir in AXIAL_DIRECTIONS:
				var j = _convert_axial_to_index(axial_coord + dir)
				if j < len(data_) and j > 0:
					astar_grid.connect_points(i, j)
	
	func _convert_axial_to_index(hex_axial: Vector2i) -> int:
		var cube_coords = HexUtils.axial_to_arr_idx(hex_axial)
		var j = cube_coords.y * width_ + cube_coords.x
		return j
	
	func _convert_index_to_axial(index: int) -> Vector2i:
		return HexUtils.arr_idx_to_axial(data_[index].x, data_[index].y)
	
	func get_neighbours(source_grid_index: int) -> Array[int]:
		return astar_grid.get_point_connections(source_grid_index)
	
	# return an internal representation to that the grid uses 
	func get_grid_index(source_hex_in_axial: Vector2i) -> int:
		return _convert_axial_to_index(source_hex_in_axial)
	
	func get_cost(hex_index: int) -> int:
		return data_[hex_index].cost
		
	func get_position(hex_index: int) -> Vector2i:
		return astar_grid.get_point_position(hex_index)
		
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

const UnitScene = preload("res://unit.tscn")

@export var terrain: TerrainGrid = null
@onready var grid_width = terrain.grid_width
@onready var grid_height = terrain.grid_height
var floating_text_scene_ = preload("res://floating_text.tscn")
var grid_ : Grid

var units = {}
var mech_types_ = {}

enum State { 	PLAYER_IDLE, 
				PLAYER_UNIT_SELECTED, 
				PLAYER_TARGETING, 
				PLAYER_MOVING,
				PLAYER_MOVING_2}
var current_state : State = State.PLAYER_IDLE
var current_selected_unit: Unit = null
var current_target_mode_: TargetState = TargetState.new()
var current_player: int = 0
var last_clicked_hex_: Vector2i = Vector2i(-9999, -9999)

func get_hex_data(hex: Vector2i) -> HexData:
	var ret: HexData = HexData.new()
	if hex in units.keys():
		ret.unit = UnitData.new(units[hex], 0)
	return ret
		

func add_unit(r: int, q: int, mech_type: MechChassis) -> Unit:
	var location_vec = Vector2i(r,q)
	var new_unit: Unit = UnitScene.instantiate()
	add_child(new_unit)
	new_unit.initalize(location_vec, terrain, mech_type)
	units[location_vec] = new_unit
	return new_unit

# function to load all abilities at start
func load_unit_types():
	const MECH_TYPE_PATH = "res://"
	var mechs_to_load = [
		"everest.tres",
	]
	for mtl in mechs_to_load:
		var mech: MechChassis = load(MECH_TYPE_PATH + mtl)
		mech_types_[mech.chassis_name_] = mech

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

func initalize():
	grid_ = Grid.new(grid_width, grid_height)
	var a = add_unit(16, 10, mech_types_["Everest"])
	var b = add_unit(13, 14, mech_types_["Everest"])
	var ass_rifle = load("res://assualt_rifle.tres")
	a.add_weapon(ass_rifle, MechChassis.MountType.HEAVY)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	SignalBus.end_turn.connect(_on_end_turn)
	SignalBus.unit_weapon_selected.connect(_on_unit_weapon_selected)
	SignalBus.ui_hex_hovered.connect(_on_hex_hovered)
	SignalBus.ui_hex_selected.connect(_on_hex_selected)
	
	load_unit_types()
	
func move_unit(unit: Unit, path: Array[Vector2i], yh: float):
	var target: Vector2i = path[-1]
	unit.set_location(target, yh)
	unit.move_points -= len(path)
	SignalBus.unit_finished_ability.emit(unit)

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
	
	
func _on_hex_selected(selected_hex: Vector2i) -> void:
	handle_click_hex(selected_hex)

func handle_select_unit(unit: Unit) -> void:
	unit.select()
	current_selected_unit = unit
	current_state = State.PLAYER_UNIT_SELECTED
	SignalBus.unit_selected.emit(unit)

func handle_deselect_unit() -> void:
	current_selected_unit.deselect()
	current_selected_unit = null
	SignalBus.unit_cleared.emit()
	current_state = State.PLAYER_IDLE

func convert_hex_to_terrain_coords(hex: Vector2i) -> Vector3:
	var global_pos: Vector3 = HexUtils.axial_to_world(hex)
	global_pos.y = terrain.get_y_height(Vector2i(hex)) + 0.05
	return terrain.to_local(global_pos)

func get_move_path(start_world_pos: Vector2i, end_world_pos: Vector2i, dist: int) -> Array[Vector2i]:
	var path: Array[Vector2i] = []
	var nudge := Vector2(1e-6, 1e-6)
	var float_origin: Vector2 = Vector2(start_world_pos) + nudge
	var float_end: Vector2 = Vector2(end_world_pos) + nudge
	var t: float = 1.0/dist
	for i in range(1,dist+1): #add +1 so we get full lerped
		var float_pos: Vector2 = float_origin.lerp(float_end, i * t)
		var lerped_hex: Vector2i = HexUtils.cube_round(float_pos.x, float_pos.y)
	
		#path.append(convert_hex_to_terrain_coords(lerped_hex))
		path.append(lerped_hex)
	return path

func get_unit_move_path(unit: Unit, target_hex: Vector2i) -> Array[Vector2i]:
	var unit_world_pos: Vector3 = unit.get_position_in_world()
	var unit_axial_pos = HexUtils.world_to_axial(unit_world_pos)
	var dist: int = HexUtils.get_axial_distance(target_hex, unit_axial_pos)
	if dist <= unit.get_movement():
		var path: Array[Vector2i] = get_move_path(unit_axial_pos, target_hex, dist)
		if len(path) <= unit.get_movement():
			return path
	return []
		
func handle_click_hex(clicked_hex: Vector2i) -> void:
	match current_state:
		State.PLAYER_IDLE:
			if clicked_hex in units:
				var picked_unit = units[clicked_hex]
				handle_select_unit(picked_unit)
		State.PLAYER_UNIT_SELECTED:
			if clicked_hex in units:
				var picked_unit = units[clicked_hex]
				if false:
					handle_deselect_unit()
				else:
					handle_select_unit(picked_unit)
		State.PLAYER_TARGETING:
				if clicked_hex in units:
					var picked_unit = units[clicked_hex]
					var damage: int = await current_selected_unit.quick_attack(picked_unit)
					SignalBus.unit_finished_ability.emit(picked_unit)
					var dmg_text = floating_text_scene_.instantiate()
					get_tree().current_scene.add_child(dmg_text)
					# 4. WAIT for the floating number to finish animating
					await dmg_text.display(str(damage), picked_unit.global_position, true)
		State.PLAYER_MOVING:
				if clicked_hex in units:
					var picked_unit = units[clicked_hex]
					if picked_unit == current_selected_unit:
						handle_deselect_unit()
				else:
					pass
		State.PLAYER_MOVING_2:
				if clicked_hex in units:
					var picked_unit = units[clicked_hex]
					if picked_unit == current_selected_unit:
						handle_deselect_unit()
				else:
					pass
			
	return

func _on_unit_weapon_selected(unit: Unit, weapon: WeaponType) -> void:
	current_target_mode_.weapon_ = weapon
	current_target_mode_.origin_pos_ = unit.get_position_in_world()
	current_target_mode_.targeting_ = true
	current_state = State.PLAYER_TARGETING

func _on_end_turn() -> void:
	pass
	#current_selected_unit = null
	#current_player += 1
	#if (current_player) == num_players:
	#	end_round()
	
func end_round() -> void:
	current_player = 0

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

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
	
	
	return reachable.keys().map(func(x) : grid_.get_position(x))
	
	
	
