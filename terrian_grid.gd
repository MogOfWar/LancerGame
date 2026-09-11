@tool
class_name TerrainGrid
extends StaticBody3D

var hex_size: float = HexUtils.hex_size

@export var grid_: GridData = null

func _ready() -> void:
	pass
	#if grid_:	
	#	print("generated blue grid")
	#	generate_rectangle_hex_grid(grid_)


func initalize(grid: GridData) -> void:
	if grid_:
		Utils.log_error("GridData: grid already initalized")
	grid_ = grid
	render_tactical_grid(grid_)
	generate_physics_grid(grid_)
	
			
func finalize_mesh(st: SurfaceTool):
	var new_mesh = st.commit()
	
	# Extract the triangle layout and assign it
	#$CollisionShape3D.shape = new_mesh.create_trimesh_shape()
		
	return new_mesh
	
func get_y_height(grid_loc: Vector2i) -> float:
	var r = grid_loc.y
	var q = grid_loc.x
	var row = r
	var col = q + (row/2)
	return grid_.get_height_from_cr(col, row)
	
func generate_rectangle_hex_grid(grid: GridData) -> void:
	# 1. Initialize the SurfaceTool
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var height: int = grid.height_
	var width: int = grid.width_
	var current_vertex_index: int = 0
	for row in range(height):
		for col in range(width):
			# THE MAGIC FORMULA:
			# integer division (row / 2) automatically drops the decimal.
			# This pushes the hex leftward on every other row.
			var q = col - (row / 2) 
			var r = row

			draw_hex(st, q, r, current_vertex_index, grid.get_height_from_cr(col, row))
			current_vertex_index += 7
			
	# 3. Finalize the mesh
	st.generate_normals() # Automatically calculates lighting/shading
	var new_mesh = finalize_mesh(st)
	$MeshInstance3D.mesh = new_mesh

func draw_hex(st: SurfaceTool, q: int, r: int, center_index: int, y_height: float) -> void:
	# Calculate world center for this hex
	var center = HexUtils.axial_to_world(Vector2(q,r))
	var center_x = center.x#hex_size * sqrt(3.0) * (q + r / 2.0)
	var center_z = center.z#hex_size * (3.0 / 2.0) * r
	
	# Sample height at the center	
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

# Helper function to color the vertices
func get_biome_color(y: float) -> Color:
	if y < 0: return Color.hex(0x2a75ff)
	if y < 2.5: return Color.hex(0x3bb143)
	return Color.hex(0x808080)
	
# 1. Define your asset library (you could also export this as a Dictionary in the Inspector)
var mesh_library: Dictionary = {
	"Grass": preload("res://art/hex_grass.res"),
	"Water": preload("res://art/hex_water.res"),
	"River": preload("res://art/hex_water.res"),
	"Forest": preload("res://art/trees_A_medium.res")
}

func render_tactical_grid(grid: GridData) -> void:
	# 2. Prepare buckets to hold the Transform3D for each instance
	var transform_buckets: Dictionary = {
		"Grass": [],
		"Water": [],
		"Forest": [],
		"River": []
	}
	
	# 3. Pass 1: Analyze the logical grid and bucket the transforms
	var total_cells: int = grid.cells_.size() #
	for i in range(total_cells):
		var cell: CellData = grid.cells_[i] #[cite: 1]
		var qr = HexUtils.arr_idx_to_axial(cell.x, cell.y)
		# Calculate 3D position
		
		var center_2d = HexUtils.axial_to_world(qr)
		var pos := Vector3(center_2d.x, cell.height, center_2d.z) #[cite: 1, 2]
		var hex_transform := Transform3D().scaled(Vector3(0.8, 0.8, 0.8)).translated(pos)
		
		# --- TERRAIN MESH BUCKETING ---
		if cell.type == "Forest":
			transform_buckets["Grass"].append(hex_transform)
			var tree_pos = pos + Vector3(0, 0.1, 0)
			
			# Optional: Give trees a random rotation so the forest looks organic
			var tree_transform = Transform3D().translated(tree_pos)
			#tree_transform = tree_transform.rotated(Vector3.UP, randf() * TAU)
			
			transform_buckets["Forest"].append(tree_transform)
		else:
			transform_buckets[cell.type].append(hex_transform)
			
		
			

	# 4. Pass 2: Create a MultiMeshInstance3D for each populated bucket
	for mesh_key in transform_buckets:
		var transforms: Array = transform_buckets[mesh_key]
		var instance_count: int = transforms.size()
		
		if instance_count == 0:
			continue # Skip if no hexes/doodads of this type exist
			
		var mmi := MultiMeshInstance3D.new()
		var multimesh := MultiMesh.new()
		multimesh.transform_format = MultiMesh.TRANSFORM_3D
		multimesh.mesh = mesh_library[mesh_key]
		
		# You MUST set the instance_count before assigning transforms
		multimesh.instance_count = instance_count
		
		for j in range(instance_count):
			multimesh.set_instance_transform(j, transforms[j])
			
		mmi.multimesh = multimesh
		add_child(mmi)

func generate_hex_collision_shape() -> ConvexPolygonShape3D:
	var shape = ConvexPolygonShape3D.new()
	var points = PackedVector3Array()
	
	var thickness = 0.05
	
	for i in range(6):
		# Standard pointy-topped hex math[cite: 2]
		var angle_rad = deg_to_rad(60 * i - 30) 
		var corner_x = HexUtils.hex_size * cos(angle_rad)
		var corner_z = HexUtils.hex_size * sin(angle_rad)
		
		# Add a top point and a bottom point for each corner
		points.append(Vector3(corner_x, thickness, corner_z))
		points.append(Vector3(corner_x, -thickness, corner_z))
		
	shape.points = points
	return shape

func generate_cylinder_collision_shape() -> CylinderShape3D:
	var shape = CylinderShape3D.new()
	shape.height = 0.05 # Give it some thickness 
	shape.radius = HexUtils.hex_size * 0.866
	return shape
	
func generate_physics_grid(grid: GridData) -> void:
	var total_cells: int = grid.cells_.size()
	for i in range(total_cells):
		var cell: CellData = grid.cells_[i]
		
		# Generate a hex-shaped collision cylinder
		
		
		# Create the collision node
		var collision_node = CollisionShape3D.new()
		collision_node.shape = generate_hex_collision_shape()
		
		# Position it exactly where the MultiMesh instance is
		var qr = HexUtils.arr_idx_to_axial(cell.x, cell.y)
		var center_2d = HexUtils.axial_to_world(qr)
		
		# Center the collision shape on the hex's vertical midpoint
		var pos_y = cell.height 
		collision_node.position = Vector3(center_2d.x, pos_y, center_2d.z)
		
		add_child(collision_node)
