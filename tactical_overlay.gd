extends Node3D

class_name TacticalOverlay

class HighlightShape:
	var template: WeaponType.TargetMode = WeaponType.TargetMode.Single
	var radius: int = 0
	var origin_pos

enum CursorGroup {
	ACTIVE = 0,
	PREVIEW = 1,
	SELECTION = 2,
	
	NUM_CONTAINERS
}

@export var hex_cursor_scene_: PackedScene
@export var path_overlay_scene_: PackedScene
@export var terrain_grid: TerrainGrid = null
@onready var single_hex_cursor: Node3D = $HexCursor
@onready var active_container = $ActiveCursorsContainer
@onready var preview_container = $PreviewCursorsContainer
@onready var selection_container = $SelectCursorsContainer
@onready var breadcrumb_container: Node3D = $BreadcrumbContainer

# Tracks the hex currently under the mouse to prevent redundant animations
var current_hovered_hex: Vector2i = Vector2i(-9999, -9999) 
var current_shape_: HighlightShape = HighlightShape.new()
var terrain_: TerrainGrid = null
var spawned_dots_: Array[Node3D] = []
var containers_: Array[Node]
var path_overlay_: PathOverlay

func _ready() -> void:
	containers_.resize(CursorGroup.NUM_CONTAINERS)
	containers_[CursorGroup.ACTIVE] = active_container
	containers_[CursorGroup.PREVIEW] = preview_container
	containers_[CursorGroup.SELECTION] = selection_container
	path_overlay_ = path_overlay_scene_.instantiate()
	add_child(path_overlay_)
	
func clear_highlighters(cursor_group: CursorGroup):
	for child in containers_[cursor_group].get_children():
		child.queue_free()

func draw_highlights(hexes_to_draw_qr: Array[Vector2i], color: Color, cursor_group: CursorGroup) -> void:
	clear_highlighters(cursor_group)
	if len(hexes_to_draw_qr) == 0:
		#hide everything has cursor off map
		single_hex_cursor.visible = false
	elif len(hexes_to_draw_qr) == -1:
		single_hex_cursor.visible = true
		single_hex_cursor.global_position = convert_hex_to_terrain_coords(hexes_to_draw_qr[0])
	else:
		single_hex_cursor.visible = false
		for hex_pos in hexes_to_draw_qr:
			var cursor: HexCursor = hex_cursor_scene_.instantiate()
			cursor.set_color(color)
			containers_[cursor_group].add_child(cursor)
			cursor.global_position = convert_hex_to_terrain_coords(hex_pos)
			
# ---------------------------------------------------------
# DRAWING LOGIC (Only runs when the hex actually changes)
# ---------------------------------------------------------
"""
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
"""
func convert_hex_to_terrain_coords(hex: Vector2i) -> Vector3:
	var global_pos: Vector3 = HexUtils.axial_to_world(hex)
	global_pos.y = terrain_grid.get_y_height(hex)
	return terrain_grid.to_local(global_pos)

func draw_breadcrumbs(hex_positions: Array[Vector2i]):
	# 1. Clean up any existing path first
	clear_breadcrumbs()
	var hex_pos_xyz: Array[Vector3] = []
	# 2. Spawn the new dots
	for i in range(hex_positions.size()):
		hex_pos_xyz.append(convert_hex_to_terrain_coords(hex_positions[i]))
	path_overlay_.preview_move_path(hex_pos_xyz)
	
func clear_breadcrumbs():
	path_overlay_.clear_preview()
	
func clear_preview():
	clear_breadcrumbs()
	clear_highlighters(CursorGroup.PREVIEW)
