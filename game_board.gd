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

enum State { PLAYER_IDLE, PLAYER_UNIT_SELECTED, PLAYER_TARGETING}
var current_state : State = State.PLAYER_IDLE
var current_selected_unit: Unit = null
var current_target_mode_: TargetState = TargetState.new()
var current_player: int = 0

func pick_hex_at_mouse():
	var camera = camera_controller.get_camera()
	if not camera:
		return null
		
	# 1. Get mouse position and project a ray into 3D space
	var mouse_pos = get_viewport().get_mouse_position()
	var ray_origin = camera.project_ray_origin(mouse_pos)
	var ray_end = ray_origin + camera.project_ray_normal(mouse_pos) * 1000.0
	
	# 2. Query Godot's physics space state
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
	query.collide_with_bodies = true
	
	var result = space_state.intersect_ray(query)
	
	# 3. If the ray hits our terrain body
	if result and result.collider is StaticBody3D:
		var hit_position = result.position # Exact Vector3 point on the terrain slope
		var clicked_hex = HexUtils.world_to_axial(hit_position)
		print("Successfully clicked Hex -> q: ", clicked_hex.x, ", r: ", clicked_hex.y)
		return clicked_hex
	return null
		
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
		var global_pos: Vector3 = HexUtils.axial_to_world(x)
		global_pos.y = terrain.get_y_height(x)
		var local_pos: Vector3 = terrain.to_local(global_pos)
		local_pos.y += 0.05
		draw_hexes.append(local_pos)
	
	SignalBus.ui_draw_highlights.emit(draw_hexes)	
	
	
func _on_hex_selected(selected_hex: Vector2i) -> void:
	handle_click_hex(selected_hex)

func handle_select_unit(unit: Unit) -> void:
	unit.select()
	current_selected_unit = unit
	current_state = State.PLAYER_UNIT_SELECTED
	SignalBus.unit_selected.emit(unit)
	
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
					picked_unit.deselect()
					SignalBus.unit_cleared.emit()
					current_state = State.PLAYER_IDLE
				else:
					handle_select_unit(picked_unit)
		State.PLAYER_TARGETING:
					if current_selected_unit.targeting_:
						var picked_unit = units[clicked_hex]
						var damage: int = await current_selected_unit.quick_attack(picked_unit)
						SignalBus.unit_finished_ability.emit(picked_unit)
						var dmg_text = floating_text_scene_.instantiate()
						get_tree().current_scene.add_child(dmg_text)
						# 4. WAIT for the floating number to finish animating
						await dmg_text.display(str(damage), picked_unit.global_position, true)
	return

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
