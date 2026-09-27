@abstract
extends Node3D
class_name Unit

var unit_data_: UnitData

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	SignalBus.vis_unit_spawned.emit(self)

func initalize(unit_data: UnitData) -> void:
	unit_data_ = unit_data
	set_location(unit_data_.get_pos_qry())

func calc_location_from_qry(pos_qry: Vector3) -> Vector3:
	var loc_qr = Vector2(pos_qry.x, pos_qry.y)
	var new_pos: Vector3 = Vector3.ZERO
	var occupied_hexes = HexUtils.get_occupied_hexes(loc_qr, unit_data_.get_size())
	for ocp in occupied_hexes:
		new_pos += HexUtils.axial_to_world(ocp)
	new_pos /= len(occupied_hexes)
	new_pos.y = pos_qry.z
	return new_pos

func set_location(pos_qry: Vector3) -> void:
	var new_pos: Vector3 = calc_location_from_qry(pos_qry)
	set_position(new_pos)
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _exit_tree():
	# Important: Tell the manager to delete the UI when this unit is destroyed    
	SignalBus.unit_died.emit(self)

@abstract func move(src_qry: Vector3, hex_qry: Vector3)
@abstract func play_attack_animation(tar_global_pos: Vector3) -> void
@abstract func play_idle_animation() -> void
@abstract func get_weapon_global_pos() -> Vector3
