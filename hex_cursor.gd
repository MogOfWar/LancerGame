extends MeshInstance3D
class_name HexCursor

@export var color_: Color = Color.WHITE

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var mat = material_override as ShaderMaterial
	mesh.top_radius = HexUtils.hex_size
	mat.set_shader_parameter("radius", HexUtils.hex_size)
	
func set_color(color: Color) -> void:
	color_ = color
	set_instance_shader_parameter("albedo", color_)
