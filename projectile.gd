extends Node3D

@onready var particles = $GPUParticles3D

func impact():
	# Stop emitting new particles but let the existing trail fade
	particles.emitting = false
	
	# Wait for the remaining particles to complete their lifetime
	await get_tree().create_timer(particles.lifetime).timeout
	queue_free()
	
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
