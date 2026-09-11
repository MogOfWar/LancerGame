@tool
extends Node3D

enum Mode {
	Random,
	Flat
}

@export var grid_: GridData = null
@export var generate_: bool = false:
	set(value):
		generate_ = false # Immediately uncheck the box
		clear_children($Entities)
		if Engine.is_editor_hint(): # Ensure this only runs in the editor
			if mode == Mode.Flat:
				if not grid_:
					grid_ = NoiseGrid.new(10,10,null)
				_run_generations()
			elif mode == Mode.Random:
				_random_terrain()
				
@export var mode: Mode = Mode.Flat
@export var seed_value: int = 12345
@export var sea_level_: float = 0
@export var save_: bool = false:
	set(value):
		save_ = false
		if grid_ == null:
			
			print("first need to generate a grid")
		else:
			_prompt_and_save()

var elevation_noise: FastNoiseLite
var forest_noise: FastNoiseLite
var river_noise: FastNoiseLite


func _prompt_and_save() -> void:
	var dialog := EditorFileDialog.new()
	dialog.file_mode = EditorFileDialog.FILE_MODE_SAVE_FILE
	dialog.add_filter("*.tres", "Resource Files")
	
	dialog.file_selected.connect(func(path: String):
		_save_resource(grid_, path)
		dialog.queue_free()
	)
	
	EditorInterface.get_base_control().add_child(dialog)
	dialog.popup_file_dialog()
	
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func spawn_hex_prism(pos: Vector3 = Vector3.ZERO, height: float = 0.5) -> MeshInstance3D:
	var mesh_node := MeshInstance3D.new()
	var radius: float = HexUtils.hex_size * 0.9 # make them a bit smaller so we can move them
	var cylinder := CylinderMesh.new()
	cylinder.radial_segments = 6 # Transforms cylinder into a hex
	cylinder.top_radius = radius
	cylinder.bottom_radius = radius
	cylinder.height = height
	
	mesh_node.mesh = cylinder
	mesh_node.position = pos
	
	add_child(mesh_node)
	
	if Engine.is_editor_hint():
		mesh_node.owner = get_tree().edited_scene_root
	
	return mesh_node

func load_mesh_type(pos: Vector3, height, type) -> MeshInstance3D:
	var mesh_dict ={
		"Water" : "res://art/hex_water.res",
		"Grass" : "res://art/hex_grass.res",
		"River" : "res://art/hex_water.res",
		"Forest": "res://art/hex_grass.res"
	}
	var mesh_node := MeshInstance3D.new()
	mesh_node.mesh = load(mesh_dict[type])
	mesh_node.position = pos
	
	if type == "Forest":
		var doodad_node = MeshInstance3D.new()
		doodad_node.mesh = load("res://art/trees_A_medium.res")
		doodad_node.position += Vector3(0,0.1,0)
		mesh_node.add_child(doodad_node)
		
	$Entities.add_child(mesh_node)
	
	if Engine.is_editor_hint():
		mesh_node.owner = get_tree().edited_scene_root
	
	return mesh_node

func clear_children(parent: Node) -> void:
	for child in parent.get_children():
		child.free()

func draw_hex(st: SurfaceTool, q: int, r: int, center_index: int, y_height: float, type) -> void:
	# Calculate world center for this hex
	var center = HexUtils.axial_to_world(Vector2(q,r))
	var center_x = center.x#hex_size * sqrt(3.0) * (q + r / 2.0)
	var center_z = center.z#hex_size * (3.0 / 2.0) * r
	
	# Sample height at the center	
	var center_pos = Vector3(center_x, y_height, center_z)
	if type == "":
		var mesh = spawn_hex_prism(center_pos)
	else:
		load_mesh_type(center_pos, 1, type)

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
			var cell = grid_.get_cell_from_cr(col, row)
			draw_hex(st, q, r, current_vertex_index, grid.get_height_from_cr(col, row), cell.type)
			current_vertex_index += 7
	
func _run_generations():
	generate_rectangle_hex_grid(grid_)

func _setup_noise(seed_value: int):
	# 1. Heightmap Noise
	elevation_noise = FastNoiseLite.new()
	elevation_noise.seed = seed_value
	elevation_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	elevation_noise.frequency = 0.05
	
	# 2. Forest/Clustering Noise
	forest_noise = FastNoiseLite.new()
	forest_noise.seed = seed_value + 1 # Offset seed so it doesn't match elevation
	forest_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	forest_noise.frequency = 0.15 # Higher frequency = smaller, tighter forest clusters
	
	# 3. River Noise (Using Ridged noise to create vein-like paths)
	river_noise = FastNoiseLite.new()
	river_noise.seed = seed_value + 2
	river_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	river_noise.fractal_type = FastNoiseLite.FRACTAL_RIDGED
	river_noise.frequency = 0.08

func generate(grid: GridData) -> void:
	# Assume grid has been initialized with empty CellData objects[cite: 1]
	for i in range(len(grid.cells_)):
		var cell: CellData = grid.cells_[i]
		cell.type = "Grass"
		# We use the cr_coords (col, row) for noise sampling
		var col = cell.x
		var row = cell.y
		
		# --- STEP 1: ELEVATION & SEA ---
		var raw_elevation = elevation_noise.get_noise_2d(col, row)
		
		# Snapping to tactical levels (e.g., -1 to 1 becomes 0, 1, 2, 3)
		# This creates flat plateaus instead of smooth rolling hills
		var stepped_height = floor((raw_elevation + 1.0) * 10.0) / 20
		
		if stepped_height <= sea_level_:
			cell.height = sea_level_ # Sea Level
			cell.type = "Water"
		else:
			cell.height = stepped_height
			
		# --- STEP 2: ISO-HEIGHT RIVERS ---
		# Only evaluate rivers on land
		if cell.height > sea_level_:
			var river_val = river_noise.get_noise_2d(col, row)
			
			# Ridged noise pushes values near 1.0 into thin lines
			if river_val > 0.85: 
				# Force the terrain down to a flat river level (Iso-height)
				cell.height = sea_level_ + 0.05 
				cell.cost += 1.0 # Rivers might cost more movement[cite: 1]
				cell.type = "River"
		
		
				
		# --- STEP 3: FORESTS (DOODADS) ---
		# Forests only spawn on land, and not in rivers
		if cell.height > sea_level_ and not "River" == cell.type:
			var flora_val = forest_noise.get_noise_2d(col, row)
			
			# By just thresholding the noise, it naturally creates the "clustered" 
			# effect you described, growing outward from a dense center.
			if flora_val > 0.3:
				cell.type = "Forest"
				cell.cost += 0.5 # Forests provide cover but cost movement[cite: 1]
		
func _random_terrain():
	_setup_noise(seed_value)
	grid_ = NoiseGrid.new(10,10, null)
	generate(grid_)
	print(grid_.cells_.size())
	generate_rectangle_hex_grid(grid_)
	
func _save_resource(grid: GridData, path: String):
	# create a new new_grid : GridData, since grid can be pointing to a derived class so make sure we only save the base class
	var new_grid : GridData = GridData.new()
	new_grid.init_from_cells(grid.cells_, grid_.width_, grid_.height_)
	ResourceSaver.save(new_grid, path)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
