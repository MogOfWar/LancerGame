extends Node3D
const UnitScene = preload("res://unit.tscn")

@onready var terrain: TerrainGrid = $Terrian
@onready var grid_width = terrain.grid_width
@onready var grid_height = terrain.grid_height
@export var camera_controller: CameraPivot

enum State { PLAYER_IDLE, PLAYER_UNIT_SELECTED}

var units = {}
var current_state : State = State.PLAYER_IDLE
var current_selected_unit: Unit = null
var abilities = {}

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
		
func add_unit(r: int, q: int, abilities) -> void:
	var location_vec = Vector2i(r,q)
	var new_unit: Unit = UnitScene.instantiate()
	add_child(new_unit)
	new_unit.initalize(location_vec, terrain, $UI_Manager)
	for a in abilities:
		new_unit.add_ability(a)
	units[location_vec] = new_unit

# function to load all abilities at start
func load_abilities():
	const ABILITY_PATH = "res://"
	var abilities_to_load = [
		"laser_gun.tres",
	]
	for atl in abilities_to_load:
		var ability = load(ABILITY_PATH + atl)
		abilities[ability.ability_name] = ability
		
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	load_abilities()
	add_unit(16, 10, [abilities["Moo"]])
	add_unit(13, 14, [abilities["Moo"]])
	
func handle_state(clicked_hex: Vector2i) -> void:
	match current_state:
		State.PLAYER_IDLE:
			if clicked_hex in units:
				var picked_unit = units[clicked_hex]
				picked_unit.select()
				current_selected_unit = picked_unit
				current_state = State.PLAYER_UNIT_SELECTED
				SignalBus.unit_selected.emit(picked_unit)
		State.PLAYER_UNIT_SELECTED:
			if clicked_hex in units:
				var picked_unit = units[clicked_hex]
				if picked_unit == current_selected_unit:
					picked_unit.deselect()
					SignalBus.unit_cleared.emit()
					current_state = State.PLAYER_IDLE
				else:
					if current_selected_unit.targeting_:
						current_selected_unit.activate_ability(picked_unit, 0)
						SignalBus.unit_finished_ability.emit(picked_unit)
			else:
				current_selected_unit.move(clicked_hex)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var clicked_hex = pick_hex_at_mouse()
		if clicked_hex:
			handle_state(clicked_hex)
			

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
