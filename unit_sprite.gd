class_name UnitSprite
extends Unit

var targeting_: bool = false


@onready var animation_player_ = $Visuals/AnimationPlayer

func _set_up_animations() -> void:
	var a: Animation = animation_player_.get_animation("mech_library/Idle_south")
	a.loop_mode = Animation.LOOP_LINEAR
	
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_set_up_animations()
	play_idle_animation()
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func select():
	$SelectionRing.visible = true

func deselect():
	$SelectionRing.visible = false

func get_animation(direction: Vector3) -> String:
	var anim_name = "mech_ani_library_2/walk_" 
	# 1. Determine if we need to flip horizontally
	if direction.x > 0:
		# Moving Right (East, NE, SE)
		$Visuals/MechSprite.flip_h = false # Flip the entire visual container
	elif direction.x < 0:
		# Moving Left (West, NW, SW)
		$Visuals/MechSprite.flip_h = true  # Face normal

	# 2. Determine the base animation name
	# We round the direction to snap it to pure 8-way angles
	var snapped_dir = Vector2(direction.x, direction.y).snapped(Vector2(1, 1))
	
	if snapped_dir.y < 0:
		if snapped_dir.x == 0:
			anim_name += "n"
		else:
			anim_name += "ne" # Used for both NW and NE (since NE is flipped)
			
	elif snapped_dir.y > 0:
		if snapped_dir.x == 0:
			anim_name += "s"
		else:
			anim_name += "se" # Used for both SW and SE
			
	else:
		anim_name += "e" # Used for both W and E
		
	# 3. Play the animation
	return anim_name

func get_animation2(direction: Vector3, base_anim_name: String):
	const facing_map = ["south", "south-east", "east", "north-east", "north", "north-west", "west", "south-west"]
	var angle = atan2(direction.x, direction.z)
	var facing_dir: int = roundi((angle) * (4 / PI))
	var anim_name: String = "mech_library/%s_%s" % [base_anim_name, facing_map[(facing_dir + 8) % 8]]
	return anim_name
	
func move(src_qry: Vector3, hex_qry: Vector3):
	# 1. Update facing direction based on movement vector	
	var direction = (hex_qry - src_qry)
	var anim_name: String = get_animation2(Vector3(direction.x, direction.z, direction.y), "Walking")
	var anim = animation_player_.get_animation(anim_name)	
	if anim:
		# Set the loop mode to wrap/loop
		anim.loop_mode = Animation.LOOP_LINEAR
	animation_player_.play(anim_name)
	
	var target_pos: Vector3 = calc_location_from_qry(hex_qry)
	target_pos.y = hex_qry.z
	# 2. Tween to the next point (adjust duration per tile as needed)
	var distance = global_position.distance_to(target_pos)
	var duration = distance / 3.0 # Speed factor
		
	var tween = create_tween()
	tween.tween_property(self, "global_position", target_pos, duration)
	await tween.finished
	animation_player_.stop()

func play_attack_animation(tar_global_pos: Vector3) -> void:
	var direction: Vector3 = (tar_global_pos - global_position)
	animation_player_.play(get_animation2(direction, "attacking"))
	
func play_idle_animation() -> void:
	
	animation_player_.play("mech_library/Idle_south")

func get_weapon_global_pos() -> Vector3:
	return $Visuals/MechSprite/MuzzleFire.global_position
	
	
