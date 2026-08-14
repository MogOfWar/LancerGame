extends MeshInstance3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var mat = material_override as ShaderMaterial
	mesh.top_radius = HexUtils.hex_size
	mat.set_shader_parameter("radius", HexUtils.hex_size)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
