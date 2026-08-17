extends Node3D

class HighlightShape:
	var template: WeaponType.TargetMode = WeaponType.TargetMode.Single
	var radius: int = 0
	var origin_pos

@export var hex_cursor_scene_: PackedScene
@export var terrain_grid: TerrainGrid = null
@onready var single_hex_cursor: Node3D = $HexCursor
@onready var container = $ActiveCursorsContainer

# Tracks the hex currently under the mouse to prevent redundant animations
var current_hovered_hex: Vector2i = Vector2i(-9999, -9999) 
var current_shape_: HighlightShape = HighlightShape.new()
var terrain_: TerrainGrid = null

func _ready() -> void:
	SignalBus.ui_draw_highlights.connect(_on_draw_highlights)
	
func _on_unit_weapon_selected(unit: Unit, w: WeaponType):
	current_shape_.template = w.target_mode_
	current_shape_.radius = w.target_mode_radius_
	current_shape_.origin_pos = unit.get_position_in_world()
	# Force an update immediately so the shape changes before the mouse moves
	update_highlight(current_hovered_hex)
	
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
		print(single_hex_cursor.global_position)
	else:
		single_hex_cursor.visible = false
		for hex_pos in hexes_to_draw:
			var cursor = hex_cursor_scene_.instantiate()
			container.add_child(cursor)
			cursor.global_position = hex_pos

func update_highlight(hex_coord: Vector2i, world_pos: Vector3 = Vector3.ZERO):
	if current_shape_.template == WeaponType.TargetMode.Single:
		# Mode: Single. Clear containers and just move the permanent cursor.
		clear_highlighters()
		single_hex_cursor.visible = true
		if world_pos != Vector3.ZERO:
			single_hex_cursor.global_position = world_pos
	else: 
		# Mode: Blast/Cone. Hide the single cursor and spawn multiples.
		single_hex_cursor.visible = false
		draw_multi_highlight(hex_coord)

func draw_multi_highlight(center_hex: Vector2i):
	clear_highlighters()
	var hexes_to_draw = []
	if current_shape_.template == WeaponType.TargetMode.Blast:
		hexes_to_draw = HexUtils.get_blast_hexes(center_hex, current_shape_.radius)
		
		
	elif current_shape_.template == WeaponType.TargetMode.Line:
		var origin_hex: Vector2i = HexUtils.world_to_axial(current_shape_.origin_pos)
		var axial_dist: int = HexUtils.get_axial_distance(origin_hex, center_hex)
		var nudge := Vector2(1e-6, 1e-6)
		var float_origin: Vector2 = Vector2(origin_hex) + nudge
		var float_end: Vector2 = Vector2(center_hex) + nudge
		var step: float = 1.0 / axial_dist
		for i in range(current_shape_.radius):
			var t = i * step
			var pos = float_origin.lerp(float_end, t)
			hexes_to_draw.append(HexUtils.cube_round(pos.x, pos.y))
	elif current_shape_.template == WeaponType.TargetMode.Cone:
		var origin_hex: Vector2i = HexUtils.world_to_axial(current_shape_.origin_pos)
		#hexes_to_draw = get_hexes_in_custom_cone(origin_hex, center_hex, current_shape_.radius, 60)
			
	
# ---------------------------------------------------------
# PROCESS LOGIC (Raycasting)
# ---------------------------------------------------------
func _process(delta: float) -> void:
	return
	var camera = get_viewport().get_camera_3d()
	var mouse_pos = get_viewport().get_mouse_position()
	var ray_origin = camera.project_ray_origin(mouse_pos)
	var ray_end = ray_origin + camera.project_ray_normal(mouse_pos) * 1000.0
	
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
	query.collide_with_bodies = true
	
	var result = space_state.intersect_ray(query)
	
	if result and result.collider is TerrainGrid:
		var hit_position = result.position
		var terrain_body: TerrainGrid = result.collider
		
		var local_hit_pos = terrain_body.to_local(hit_position)
		var hovered_hex = HexUtils.world_to_axial(local_hit_pos)
		
		# OPTIMIZATION: Only update shapes if we entered a NEW hex!
		if hovered_hex != current_hovered_hex:
			current_hovered_hex = hovered_hex
			
			SignalBus.hex_hovered.emit(hovered_hex)
			
			#var local_target_pos = HexUtils.axial_to_world(hovered_hex)
			#var target_position = terrain_body.to_global(local_target_pos)
			#target_position.y = hit_position.y + 0.05
			
			# Call our draw logic
			#update_highlight(hovered_hex, target_position)
			
	#else:
		# Hide everything if mouse goes off the map
		#if current_hovered_hex != Vector2i(-9999, -9999):
		#	current_hovered_hex = Vector2i(-9999, -9999)
		#	single_hex_cursor.visible = false
		#	clear_highlighters()
