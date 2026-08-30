extends Node3D
class_name PathOverlay

@onready var mesh_: MeshInstance3D = $MeshInstance3D

func _ready() -> void:
	# Unshaded material so the line glows brightly regardless of scene lighting
	var mat = ORMMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color.CYAN
	mesh_.material_override = mat

func preview_move_path(hex_path: Array[Vector3]) -> void:
	var imm_mesh := ImmediateMesh.new()
	
	if hex_path.size() > 1:
		imm_mesh.clear_surfaces()
		imm_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
		
		for i in range(hex_path.size() - 1):
			# Slight Y-offset (+0.1) prevents Z-fighting with the ground mesh
			var start_pos = hex_path[i] + Vector3(0, 0.1, 0)
			var end_pos = hex_path[i + 1] + Vector3(0, 0.1, 0)
			
			imm_mesh.surface_add_vertex(start_pos)
			imm_mesh.surface_add_vertex(end_pos)
			
		imm_mesh.surface_end()
	
	mesh_.mesh = imm_mesh

func clear_preview() -> void:
	mesh_.mesh = null
