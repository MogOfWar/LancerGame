extends Node3D

class HighlightShape:
	var template: WeaponType.TargetMode = WeaponType.TargetMode.Single
	var radius: int = 0

@export var camera_pivot: CameraPivot
@export var hex_cursor_scene_: PackedScene
@export var single_hex_cursor: Node3D # Make sure this points to a mesh already in your scene!
@export var game_board: Node3D = null
@onready var container = $ActiveCursorsContainer

# Tracks the hex currently under the mouse to prevent redundant animations
var current_hovered_hex: Vector2i = Vector2i(-9999, -9999) 
var current_shape_: HighlightShape = HighlightShape.new()
var terrain_: TerrainGrid = null

func _ready() -> void:
	SignalBus.unit_weapon_selected.connect(_on_unit_weapon_selected)
	
func _on_unit_weapon_selected(unit: Unit, w: WeaponType):
	current_shape_.template = w.target_mode_
	current_shape_.radius = w.target_mode_radius_
	
	# Force an update immediately so the shape changes before the mouse moves
	update_highlight(current_hovered_hex)
	
func clear_highlighters():
	for child in container.get_children():
		child.queue_free()

# ---------------------------------------------------------
# DRAWING LOGIC (Only runs when the hex actually changes)
# ---------------------------------------------------------
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
	
	if current_shape_.template == WeaponType.TargetMode.Blast:
		# Replace this with your actual Blast math function
		var blast_hexes = HexUtils.get_blast_hexes(center_hex, current_shape_.radius)
		
		for hex_pos in blast_hexes:
			var cursor = hex_cursor_scene_.instantiate()
			container.add_child(cursor)
			cursor.global_position = HexUtils.axial_to_world(hex_pos) # Convert back to world space
			# (Note: you may need to apply terrain offset to Y here)

# ---------------------------------------------------------
# PROCESS LOGIC (Raycasting)
# ---------------------------------------------------------
func _process(delta: float) -> void:
	var camera = camera_pivot.get_camera()
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
			
			var local_target_pos = HexUtils.axial_to_world(hovered_hex)
			var target_position = terrain_body.to_global(local_target_pos)
			target_position.y = hit_position.y + 0.05
			
			# Call our draw logic
			update_highlight(hovered_hex, target_position)
			
	else:
		# Hide everything if mouse goes off the map
		if current_hovered_hex != Vector2i(-9999, -9999):
			current_hovered_hex = Vector2i(-9999, -9999)
			single_hex_cursor.visible = false
			clear_highlighters()
