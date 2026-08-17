class_name HexUtils
extends RefCounted

const hex_size: float = 1.0

static func get_blast_hexes(center: Vector2i, radius: int) -> Array[Vector2i]:
	var results: Array[Vector2i] = []
	
	# Loop through a bounding box and check hex distance
	for x in range(-radius, radius + 1):
		for y in range(max(-radius, -x - radius), min(radius, -x + radius) + 1):
			var offset = Vector2i(x, y)
			results.append(center + offset) # (Assuming offset coordinates)
			
	return results

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
	
static func get_axial_distance(hex_a: Vector2i, hex_b: Vector2i) -> int:
	var dq: int = hex_a.x - hex_b.x
	var dr: int = hex_a.y - hex_b.y
	
	# Distance is the maximum of the absolute differences
	return max(abs(dq), abs(dr), abs(dq + dr))

# returns a hex that is on the line BA exactly dist hexes from a
static func clamp_to_dist(a: Vector2i, b: Vector2i, dist: int) -> Vector2i:
	var axial_dist = get_axial_distance(b, a)
	var nudge := Vector2(1e-6, 1e-6)
	var float_origin: Vector2 = Vector2(a) + nudge
	var float_end: Vector2 = Vector2(b) + nudge
	var step: float = 1.0 / axial_dist
	var target: Vector2 = float_origin.lerp(float_end, dist * step)
	return cube_round(target.x, target.y)
	
static func get_hexes_in_custom_cone(origin_hex: Vector2i, target_hex: Vector2i, radius: int, cone_angle_degrees: float) -> Array[Vector2i]:
	var hexes_in_cone: Array[Vector2i] = []
	
	# 1. Get the world-space vectors
	var origin_world: Vector3 = HexUtils.axial_to_world(origin_hex)
	var target_world: Vector3 = HexUtils.axial_to_world(HexUtils.clamp_to_dist(origin_hex, target_hex, radius))

	# 2. Get the continuous forward direction
	var forward_dir: Vector3 = (target_world - origin_world).normalized()

	# 3. Iterate over a bounding box of radius
	for q in range(-radius, radius + 1):
		for r in range(max(-radius, -q - radius), min(radius, -q + radius) + 1):
			var current_hex = origin_hex + Vector2i(q, r)
			
			if current_hex == origin_hex:
				continue # Skip the origin tile if desired
				
			# 4. Check the angle
			var current_world: Vector3 = HexUtils.axial_to_world(current_hex)
			var current_dir: Vector3 = (current_world - origin_world).normalized()
			
			# Use the dot product to find the angle between the vectors
			var angle_rads: float = acos(forward_dir.dot(current_dir))
			var angle_degs: float = rad_to_deg(angle_rads)
			
			# If the angle is less than half the total cone width, it's inside
			if angle_degs <= (cone_angle_degrees / 2.0):
				hexes_in_cone.append(current_hex)
				
	return hexes_in_cone

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
