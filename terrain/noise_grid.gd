extends GridData
class_name NoiseGrid

@export var noise_: Noise
@export var height_multiplier_: float = 5.0

func _init(w: int, h: int, noise_height_map: Noise) -> void:
	width_ = w
	height_ = h
	noise_ = noise_height_map
	var cells: Array[CellData] = []
	cells.resize(w*h)
	for row in range(height_):
		for col in range(width_):
				var index: int = row * width_ + col
				var cell_data = CellData.new()
				cell_data.x = col
				cell_data.y = row
				cell_data.height = get_height_from_noise(col, row, noise_) * height_multiplier_
				cell_data.cost = 1
				cells[index] = cell_data
	
	super.init_from_cells(cells)

static func get_height_from_noise(col: int, row: int, noise: Noise) -> float:
	if noise:
		var axial: Vector2i = HexUtils.arr_idx_to_axial(col, row)
		var world = HexUtils.axial_to_world(axial)
		var y_height: float = noise.get_noise_2d(world.x, world.z) 
		return y_height
	else:
		return 0.0
