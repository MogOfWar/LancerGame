extends Resource
class_name GridData

@export var width_: int 
@export var height_: int
@export var cells_: Array[CellData]
var astar_: AStar2D


# function takes refrence from cells so don't change cells afterwards
func init_from_cells(cells: Array[CellData], width: int, height: int) -> void:
	width_ = width
	height_ = height
	astar_ = AStar2D.new()
	cells_ = cells 
	for i in range(len(cells_)):
		var cell: CellData = cells_[i]
		astar_.add_point(i, HexUtils.arr_idx_to_axial(cell.x, cell.y), cell.cost)
		
	for i in range(len(cells_)):
			var cell: CellData = cells_[i]
			var axial_coord: Vector2i = HexUtils.arr_idx_to_axial(cell.x, cell.y)
			for dir in HexUtils.AXIAL_DIRECTIONS:
				if check_hex_in_grid(axial_coord + dir):
					var j = _convert_axial_to_index(axial_coord + dir)
					astar_.connect_points(i, j)

func _convert_axial_to_index(hex_axial: Vector2i) -> int:
		var cube_coords = HexUtils.axial_to_arr_idx(hex_axial)
		var j = cube_coords.y * width_ + cube_coords.x
		return j
	
func _convert_index_to_axial(index: int) -> Vector2i:
	return HexUtils.arr_idx_to_axial(cells_[index].x, cells_[index].y)

func get_neighbours(source_grid_index: int) -> PackedInt64Array:
	return astar_.get_point_connections(source_grid_index)

# return an internal representation to that the grid uses 
func get_grid_index(source_hex_in_axial: Vector2i) -> int:
	return _convert_axial_to_index(source_hex_in_axial)

func get_cost(hex_index: int) -> int:
	return cells_[hex_index].cost
	
func get_position(hex_index: int) -> Vector2i:
	return astar_.get_point_position(hex_index)
	
func get_height_from_index(hex_index: int) -> float:
	return cells_[hex_index].height

func get_height_from_cr(col: int, row: int) -> float:
	var hex_index = row * width_ + col
	return get_height_from_index(hex_index) 
	
func get_height_from_qr(hex_qr: Vector2i) -> float:
	var grid_index: int = get_grid_index(hex_qr)
	return get_height_from_index(grid_index)
	
func check_hex_in_grid(hex_qr: Vector2i) -> bool:
	var cr_coords: Vector2i = HexUtils.axial_to_arr_idx(hex_qr)
	return ((cr_coords.x >= 0) and (cr_coords.x < width_)) and ((cr_coords.y >= 0) and (cr_coords.y < height_))

func set_point_disabled(hex_qr, disabled: bool) -> void:
	astar_.set_point_disabled(get_grid_index(hex_qr), disabled)
	
func get_cell_from_cr(col, row):
	var hex_index = row * width_ + col
	return cells_[hex_index]
	
func get_center_qr() -> Vector2:
	return HexUtils.arr_idx_to_axial(width_/2, height_/2)
