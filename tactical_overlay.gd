extends Node3D

class_name TacticalOverlay

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
var terrain_: TerrainGrid = null
var spawned_dots_: Array[Node3D] = []
var containers_: Array[Node]
var path_overlay_: PathOverlay
var targeting_mesh_: ImmediateMesh
var targeting_mesh_instance_: MeshInstance3D

func _ready() -> void:
	containers_.resize(CursorGroup.NUM_CONTAINERS)
	containers_[CursorGroup.ACTIVE] = active_container
	containers_[CursorGroup.PREVIEW] = preview_container
	containers_[CursorGroup.SELECTION] = selection_container
	path_overlay_ = path_overlay_scene_.instantiate()
	add_child(path_overlay_)
	
	# --- NEW TARGETING MESH SETUP ---
	targeting_mesh_ = ImmediateMesh.new()
	targeting_mesh_instance_ = MeshInstance3D.new()
	targeting_mesh_instance_.mesh = targeting_mesh_
	
	var material = ShaderMaterial.new()
	material.shader = preload("res://shaders/targeting_arc.gdshader")
	targeting_mesh_instance_.material_override = material
	add_child(targeting_mesh_instance_)
	
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

# target_data is an Array of Dictionaries: {"hex": Vector2i, "color": Color}
func draw_targeting_arcs(source_hex: Vector2i, target_data: Array[Dictionary]) -> void:
	targeting_mesh_.clear_surfaces()
	
	if target_data.is_empty():
		return
		
	# Convert logical hex to 3D world space using your existing terrain grid function
	var source_pos_3d: Vector3 = convert_hex_to_terrain_coords(source_hex)
	# Raise the origin point slightly above the hex floor
	source_pos_3d.y += 0.5 
	
	for data in target_data:
		var target_pos_3d: Vector3 = convert_hex_to_terrain_coords(data["hex"])
		target_pos_3d.y += 0.5
		
		_draw_single_arc(source_pos_3d, target_pos_3d, data["color"], 16, 0.2)

func _draw_single_arc(source_pos: Vector3, target_pos: Vector3, line_color: Color, segments: int = 16, line_width: float = 0.15) -> void:
	targeting_mesh_instance_.material_override.set_shader_parameter("line_color", line_color)
	var distance: float = source_pos.distance_to(target_pos)
	var max_height: float = clampf(distance * 0.15, 0.5, 3.0) 
	
	# Compute right vector perpendicular to line direction to give line width
	var dir: Vector3 = (target_pos - source_pos).normalized()
	var right: Vector3 = dir.cross(Vector3.UP).normalized() * (line_width * 0.5)

	targeting_mesh_.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
	
	for i in range(segments + 1):
		var t: float = float(i) / float(segments)
		
		# Parabolic height interpolation
		var point: Vector3 = source_pos.lerp(target_pos, t)
		point.y += 4.0 * max_height * t * (1.0 - t)
		
		# Set vertex color & UVs for left and right side of ribbon
		# UV.x = t (0.0 at start, 1.0 at target)
		# UV.y = 0.0 on left edge, 1.0 on right edge
		
		# Left vertex
		targeting_mesh_.surface_set_color(line_color)
		targeting_mesh_.surface_set_uv(Vector2(t, 0.0))
		targeting_mesh_.surface_add_vertex(point - right)
		
		# Right vertex
		targeting_mesh_.surface_set_color(line_color)
		targeting_mesh_.surface_set_uv(Vector2(t, 1.0))
		targeting_mesh_.surface_add_vertex(point + right)
		
	targeting_mesh_.surface_end()

func clear_breadcrumbs():
	path_overlay_.clear_preview()
	
func clear_preview():
	clear_breadcrumbs()
	clear_highlighters(CursorGroup.PREVIEW)
	targeting_mesh_.clear_surfaces() # Clears the targeting arcs
