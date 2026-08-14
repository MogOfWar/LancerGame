@tool
class_name TerrainGrid
extends StaticBody3D

var hex_size: float = HexUtils.hex_size
@export var grid_radius: int = 15
@export var height_multiplier: float = 5.0
@export var noise: FastNoiseLite
@export var grid_width: int = 50
@export var grid_height: int = 50
var grid_height_map = []
func _ready() -> void:
	if not noise:
		noise = FastNoiseLite.new()
		noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
		noise.seed = randi()
	
	for r in range(grid_height):
		grid_height_map.append([])
		for q in range(grid_width):
			grid_height_map[r].append(0)
			
	generate_rectangle_hex_grid(grid_width, grid_height)
	
	
			
func finalize_mesh(st: SurfaceTool):
	var new_mesh = st.commit()
	
	# Extract the triangle layout and assign it
	$CollisionShape3D.shape = new_mesh.create_trimesh_shape()
		
	return new_mesh
	
func get_y_height(grid_loc: Vector2i) -> float:
	var r = grid_loc.y
	var q = grid_loc.x
	var row = r
	var col = q + (row/2)
	return grid_height_map[row][col]
	
func generate_rectangle_hex_grid(width: int, height: int) -> void:
	# 1. Initialize the SurfaceTool
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var current_vertex_index: int = 0
	for row in range(height):
		
		for col in range(width):
			# THE MAGIC FORMULA:
			# integer division (row / 2) automatically drops the decimal.
			# This pushes the hex leftward on every other row.
			var q = col - (row / 2) 
			var r = row

			var y_height = draw_hex(st, q, r, current_vertex_index)
			current_vertex_index += 7
			grid_height_map[row][col] = y_height
			
	# 3. Finalize the mesh
	st.generate_normals() # Automatically calculates lighting/shading
	var new_mesh = finalize_mesh(st)
	$MeshInstance3D.mesh = new_mesh
	

func generate_hexagon_hex_grid() -> void:
	# 1. Initialize the SurfaceTool
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var current_vertex_index: int = 0
	
	# 2. Iterate through axial coordinates
	for q in range(-grid_radius, grid_radius + 1):
		for r in range(-grid_radius, grid_radius + 1):
			if abs(q + r) <= grid_radius:
				draw_hex(st, q, r, current_vertex_index)
				
				current_vertex_index += 7
	# 3. Finalize the mesh
	st.generate_normals() # Automatically calculates lighting/shading
	finalize_mesh(st)

func draw_hex(st: SurfaceTool, q: int, r: int, center_index: int) -> float:
	# Calculate world center for this hex
	var center = HexUtils.axial_to_world(Vector2(q,r))
	var center_x = center.x#hex_size * sqrt(3.0) * (q + r / 2.0)
	var center_z = center.z#hex_size * (3.0 / 2.0) * r
	
	# Sample height at the center
	var y_height : float  = noise.get_noise_2d(center_x, center_z) * height_multiplier
	var center_pos = Vector3(center_x, y_height, center_z)
	
	# Add Center Vertex
	st.set_color(get_biome_color(y_height)) # Optional: Color based on height
	st.set_uv(Vector2(0.0, 0.0))
	st.add_vertex(center_pos)
	
	
	# Add the 6 Corner Vertices
	for i in range(6):
		# Angle for pointy-topped hex corners (starts at 30 degrees)
		var angle_deg = 60 * i - 30
		var angle_rad = deg_to_rad(angle_deg)
		
		var corner_x = center_pos.x + hex_size * cos(angle_rad)
		var corner_z = center_pos.z + hex_size * sin(angle_rad)
		
		# Note: If you want sloped terrain, sample noise again using corner_x/z.
		# If you want flat-topped hexes (board game style), use the center's y_height.
		var corner_pos = Vector3(corner_x, y_height, corner_z)
		
		st.set_color(get_biome_color(randf()))
		st.set_uv(Vector2(1.0, 0.0))
		st.add_vertex(corner_pos)
		
	# Build the 6 Triangles (Indices)
	for i in range(6):
		st.add_index(center_index)           # Center
		
		# Current corner goes FIRST now
		st.add_index(center_index + i + 1)   
		
		# Next corner (wrap around back to 1 if we are on the last corner)
		var next_corner = center_index + i + 2
		if i == 5:
			next_corner = center_index + 1
			
		# Next corner goes LAST now
		st.add_index(next_corner)
	return y_height

# Helper function to color the vertices
func get_biome_color(y: float) -> Color:
	if y < 0: return Color.hex(0x2a75ff)
	if y < 2.5: return Color.hex(0x3bb143)
	return Color.hex(0x808080)
