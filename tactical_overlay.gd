extends Node3D

class_name TacticalOverlay

class HighlightShape:
	var template: WeaponType.TargetMode = WeaponType.TargetMode.Single
	var radius: int = 0
	var origin_pos

@export var hex_cursor_scene_: PackedScene
@export var path_dot_scene_: PackedScene
@export var terrain_grid: TerrainGrid = null
@onready var single_hex_cursor: Node3D = $HexCursor
@onready var container = $ActiveCursorsContainer
@onready var breadcrumb_container: Node3D = $BreadcrumbContainer

# Tracks the hex currently under the mouse to prevent redundant animations
var current_hovered_hex: Vector2i = Vector2i(-9999, -9999) 
var current_shape_: HighlightShape = HighlightShape.new()
var terrain_: TerrainGrid = null
var spawned_dots_: Array[Node3D] = []

func _ready() -> void:
	SignalBus.ui_draw_highlights.connect(_on_draw_highlights)
	SignalBus.tol_path_calculated.connect(draw_breadcrumbs)
	SignalBus.tol_path_cleared.connect(clear_breadcrumbs)
	
func clear_highlighters():
	for child in container.get_children():
		child.queue_free()

# ---------------------------------------------------------
# DRAWING LOGIC (Only runs when the hex actually changes)
# ---------------------------------------------------------
func _on_draw_highlights(hexes_to_draw: Array[Vector3]) -> void:
	clear_highlighters()
	if len(hexes_to_draw) == 0:
		#hide everything has cursor off map
		single_hex_cursor.visible = false
	elif len(hexes_to_draw) == 1:
		single_hex_cursor.visible = true
		single_hex_cursor.global_position = hexes_to_draw[0]
	else:
		single_hex_cursor.visible = false
		for hex_pos in hexes_to_draw:
			var cursor = hex_cursor_scene_.instantiate()
			container.add_child(cursor)
			cursor.global_position = hex_pos

func convert_hex_to_terrain_coords(hex: Vector2i) -> Vector3:
	var global_pos: Vector3 = HexUtils.axial_to_world(hex)
	global_pos.y = terrain_grid.get_y_height(hex)
	return terrain_grid.to_local(global_pos)

func draw_breadcrumbs(hex_positions: Array[Vector2i]):
	# 1. Clean up any existing path first
	clear_breadcrumbs()
	
	# 2. Spawn the new dots
	for i in range(hex_positions.size()):
		var dot = path_dot_scene_.instantiate() as Node3D
		
		# Add it to the container instead of self
		breadcrumb_container.add_child(dot)
		
		dot.global_position = convert_hex_to_terrain_coords(hex_positions[i]) + Vector3(0, 0.1, 0)
		
		if i < hex_positions.size() - 1:
			var next_pos = convert_hex_to_terrain_coords(hex_positions[i + 1]) + Vector3(0, 0.1, 0)
			dot.look_at(next_pos, Vector3.UP)

func clear_breadcrumbs():
	# Ask the container for all its children and delete them
	for child in breadcrumb_container.get_children():
		child.queue_free()
