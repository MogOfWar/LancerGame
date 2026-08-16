extends Node3D
const UnitScene = preload("res://unit.tscn")

@onready var terrain: TerrainGrid = $Terrian
@onready var grid_width = terrain.grid_width
@onready var grid_height = terrain.grid_height
@export var camera_controller: CameraPivot
var floating_text_scene_ = preload("res://floating_text.tscn")
var num_players: int = 2




var units = {}
var mech_types_ = {}

enum State { PLAYER_IDLE, PLAYER_UNIT_SELECTED}
var current_state : State = State.PLAYER_IDLE
var current_selected_unit: Unit = null
var current_target_mode_: WeaponType.TargetMode = WeaponType.TargetMode.Single
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
	new_unit.initalize(location_vec, terrain, $UI_Manager, mech_type)
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
		
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	SignalBus.end_turn.connect(_on_end_turn)
	SignalBus.unit_weapon_selected.connect(_on_unit_weapon_selected)
	load_unit_types()
	var a = add_unit(16, 10, mech_types_["Everest"])
	var b = add_unit(13, 14, mech_types_["Everest"])
	var ass_rifle = load("res://assualt_rifle.tres")
	a.add_weapon(ass_rifle, MechChassis.MountType.HEAVY)
	
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
						var damage: int = await current_selected_unit.quick_attack(picked_unit)
						SignalBus.unit_finished_ability.emit(picked_unit)
						var dmg_text = floating_text_scene_.instantiate()
						get_tree().current_scene.add_child(dmg_text)
						# 4. WAIT for the floating number to finish animating
						await dmg_text.display(str(damage), picked_unit.global_position, true)
			else:
				current_selected_unit.move(clicked_hex)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var clicked_hex = pick_hex_at_mouse()
		if clicked_hex:
			handle_state(clicked_hex)

func _on_unit_weapon_selected(unit: Unit, weapon: WeaponType) -> void:
	current_target_mode_ = weapon.target_mode_

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
