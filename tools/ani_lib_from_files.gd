@tool
extends Node

class FileDesc extends Resource:
	var file_path: String = ""
	var cell_size: int
	var hframes: int
	var name: String
	var num_frames: int
	
@export_file_path("*.png") var sprite_sheet_to_load: Array[String] = []
@export var cell_size: Array[int] = []
@export var hframes: Array[int] = []
@export var names: Array[String] = []
@export var num_frames: Array[int] = []
@export var fps = 10.0

func _load_single_file(file_desc: FileDesc) -> Animation:
	# 3. Create the Animation Resource
	var anim = Animation.new()
	var base_texture = load(file_desc.file_path)
	# 4. Add a Value Track to change the Sprite's texture
	var track_idx = anim.add_track(Animation.TYPE_VALUE)
	
	# Define the path to your Sprite3D node and the property to animate
	anim.track_set_path(track_idx, "MechSprite:texture")
	
	# CRITICAL: Set to DISCRETE so the engine snaps to the next frame instantly.
	# If left as CONTINUOUS (default), Godot will try to crossfade the images.
	anim.value_track_set_update_mode(track_idx, Animation.UPDATE_DISCRETE)

	# 5. Insert the frames
	# Assuming your JSON has an array of frame rects: [{"x":0,"y":0,"w":64,"h":64}, ...]
	
	var num_frames = file_desc.num_frames
	var time_step = 1.0 / fps
	
	# Set total animation length based on frame count
	anim.length = num_frames * time_step

	for i in range(num_frames):
		var x = i % file_desc.hframes
		var y = i / file_desc.hframes
		# Create an AtlasTexture representing just this specific frame's region
		var atlas = AtlasTexture.new()
		atlas.atlas = base_texture
		atlas.region = Rect2(
			x * file_desc.cell_size, 
			y * file_desc.cell_size, 
			file_desc.cell_size, 
			file_desc.cell_size
		)
		
		# Insert the texture into the timeline
		var time = i * time_step
		anim.track_insert_key(track_idx, time, atlas)

	# 6. Save the generated animation
	return anim
	
func _run_generations():
	var anim_library = AnimationLibrary.new()
	for i in range(len(sprite_sheet_to_load)):
		var file_desc: FileDesc = FileDesc.new()
		file_desc.cell_size = cell_size[i]
		file_desc.hframes = hframes[i]
		file_desc.file_path = sprite_sheet_to_load[i]
		file_desc.name = names[i]
		file_desc.num_frames = num_frames[i]
		var anim = _load_single_file(file_desc)
		anim_library.add_animation(file_desc.name, anim)
		
	# Save the entire library into one file
	ResourceSaver.save(anim_library,"res://art//mech_ani_library_2.res")
	
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_run_generations()
