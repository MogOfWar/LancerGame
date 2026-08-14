class_name HexUtils
extends RefCounted

const hex_size: float = 1.0

static func axial_to_world(hex: Vector2) -> Vector3:
	var q = hex.x
	var r = hex.y
	
	# Math for Pointy-Top hex orientation in 3D (X and Z axes)
	var x = HexUtils.hex_size * sqrt(3.0) * (q + r / 2.0)
	var z = HexUtils.hex_size * (3.0 / 2.0) * r
	
	return Vector3(x, 0, z)
	
static func world_to_axial(world_pos: Vector3) -> Vector2i:
	var x = world_pos.x
	var z = world_pos.z
	
	# Inverse formulas for Pointy-Topped layout
	var q_frac = (sqrt(3.0) / 3.0 * x - (1.0 / 3.0) * z) / HexUtils.hex_size
	var r_frac = (2.0 / 3.0 * z) / HexUtils.hex_size
	
	return cube_round(q_frac, r_frac)

static func cube_round(fractional_q: float, fractional_r: float) -> Vector2i:
	var q_float = fractional_q
	var r_float = fractional_r
	var s_float = -q_float - r_float
	
	var rx = round(q_float)
	var ry = round(r_float)
	var rz = round(s_float)
	
	var q_diff = abs(rx - q_float)
	var r_diff = abs(ry - r_float)
	var s_diff = abs(rz - s_float)
	
	if q_diff > r_diff and q_diff > s_diff:
		rx = -ry - rz
	elif r_diff > s_diff:
		ry = -rx - rz
	else:
		rz = -rx - ry
		
	return Vector2i(int(rx), int(ry))
