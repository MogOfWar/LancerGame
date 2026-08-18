extends Node3D

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

@onready var terrain: TerrainGrid = $TerrainGrid
@onready var grid_width = terrain.grid_width
@onready var grid_height = terrain.grid_height
@export var camera_controller: CameraPivot
var floating_text_scene_ = preload("res://floating_text.tscn")
var num_players: int = 2

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
	
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	SignalBus.end_turn.connect(_on_end_turn)
	SignalBus.unit_weapon_selected.connect(_on_unit_weapon_selected)
	SignalBus.ui_hex_hovered.connect(_on_hex_hovered)
	SignalBus.ui_hex_selected.connect(_on_hex_selected)
	SignalBus.unit_move_button_pressed.connect(_on_move_button_pressed)
	
	load_unit_types()
	var a = add_unit(16, 10, mech_types_["Everest"])
	var b = add_unit(13, 14, mech_types_["Everest"])
	var ass_rifle = load("res://assualt_rifle.tres")
	a.add_weapon(ass_rifle, MechChassis.MountType.HEAVY)

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

func get_move_path(start_world_pos: Vector2i, end_world_pos: Vector2i, dist: int):
	var path: Array[Vector3] = []
	var nudge := Vector2(1e-6, 1e-6)
	var float_origin: Vector2 = Vector2(start_world_pos) + nudge
	var float_end: Vector2 = Vector2(end_world_pos) + nudge
	var t: float = 1.0/dist
	for i in range(dist+1): #add +1 so we get full lerped
		var float_pos: Vector2 = float_origin.lerp(float_end, i * t)
		var lerped_hex: Vector2i = HexUtils.cube_round(float_pos.x, float_pos.y)
	
		path.append(convert_hex_to_terrain_coords(lerped_hex))
	return path
	

func handle_move_first_phase(clicked_hex: Vector2i) -> void:
	var unit_world_pos: Vector3 = current_selected_unit.get_position_in_world()
	var unit_axial_pos = HexUtils.world_to_axial(unit_world_pos)
	
	var dist: int = HexUtils.get_axial_distance(clicked_hex, unit_axial_pos)
	if dist <= current_selected_unit.get_movement():
		var path: Array[Vector3] = get_move_path(unit_axial_pos, clicked_hex, dist)
		current_state = State.PLAYER_MOVING_2
		last_clicked_hex_ = clicked_hex
		SignalBus.tol_path_calculated.emit(path)
		
func handle_move_second_phase(clicked_hex: Vector2i) -> void:
	if last_clicked_hex_ == clicked_hex:
		# player confirmed movement
		SignalBus.tol_path_cleared.emit()
		var dist: int = HexUtils.get_axial_distance(clicked_hex, HexUtils.world_to_axial(current_selected_unit.get_position_in_world()))
		current_selected_unit.set_location(clicked_hex, terrain.get_y_height(clicked_hex))
		current_selected_unit.move_points -= dist
		current_state = State.PLAYER_UNIT_SELECTED
		SignalBus.unit_finished_ability.emit(current_selected_unit)
		
func handle_click_hex(clicked_hex: Vector2i) -> void:
	match current_state:
		State.PLAYER_IDLE:
			if clicked_hex in units:
				var picked_unit = units[clicked_hex]
				handle_select_unit(picked_unit)
		State.PLAYER_UNIT_SELECTED:
			if clicked_hex in units:
				var picked_unit = units[clicked_hex]
				if picked_unit == current_selected_unit:
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
					handle_move_first_phase(clicked_hex)
		State.PLAYER_MOVING_2:
				if clicked_hex in units:
					var picked_unit = units[clicked_hex]
					if picked_unit == current_selected_unit:
						handle_deselect_unit()
				else:
					handle_move_second_phase(clicked_hex)
			
	return

func _on_move_button_pressed(unit: Unit) -> void:
	if unit != current_selected_unit:
		print("ERROR: wierd stuff")
	current_state = State.PLAYER_MOVING

func _on_unit_weapon_selected(unit: Unit, weapon: WeaponType) -> void:
	current_target_mode_.weapon_ = weapon
	current_target_mode_.origin_pos_ = unit.get_position_in_world()
	current_target_mode_.targeting_ = true
	current_state = State.PLAYER_TARGETING

func _on_end_turn() -> void:
	current_selected_unit = null
	current_player += 1
	if (current_player) == num_players:
		end_round()
	
func end_round() -> void:
	current_player = 0

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
