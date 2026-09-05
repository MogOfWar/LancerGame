@tool
extends Node

@export_file("*.png") var texture_path: String
@export_file("*.json") var json_path: String
@export_global_dir var save_path: String = "res://art"
@export var hframs: int
@export var vframs: int
@export var fps: float = 10.0

# This boolean acts as our "Run" button in the Inspector
@export var generate: bool = false:
	set(value):
		generate = false # Immediately uncheck the box
		if Engine.is_editor_hint(): # Ensure this only runs in the editor
			if json_path and texture_path:
				_run_generation()
			else:
				push_error("Missing arguments: Please provide JSON and Texture paths.")

func _parse_single_animation(animation_json, cell_width, cell_height, base_texture) -> Animation:
	# 3. Create the Animation Resource
	var anim = Animation.new()
	
	# 4. Add a Value Track to change the Sprite's texture
	var track_idx = anim.add_track(Animation.TYPE_VALUE)
	
	# Define the path to your Sprite3D node and the property to animate
	anim.track_set_path(track_idx, "MechSprite:texture")
	
	# CRITICAL: Set to DISCRETE so the engine snaps to the next frame instantly.
	# If left as CONTINUOUS (default), Godot will try to crossfade the images.
	anim.value_track_set_update_mode(track_idx, Animation.UPDATE_DISCRETE)

	# 5. Insert the frames
	# Assuming your JSON has an array of frame rects: [{"x":0,"y":0,"w":64,"h":64}, ...]
	var row_number = animation_json.get("row", 0)
	var num_frames = animation_json.get("frame_count", 0)
	var base_y = row_number * cell_height
	var time_step = 1.0 / fps
	
	# Set total animation length based on frame count
	anim.length = num_frames * time_step

	for i in range(num_frames):
		
		# Create an AtlasTexture representing just this specific frame's region
		var atlas = AtlasTexture.new()
		atlas.atlas = base_texture
		atlas.region = Rect2(
			i * cell_width, 
			base_y, 
			cell_width, 
			cell_height
		)
		
		# Insert the texture into the timeline
		var time = i * time_step
		anim.track_insert_key(track_idx, time, atlas)

	# 6. Save the generated animation
	return anim
	
func _get_name(animation_json) -> String:
	return "%s_%s" % [animation_json.get("animation", ""), animation_json.get("direction", "")]
	
func _run_generation():
# 1. Load the base sprite sheet
	var base_texture = load(texture_path)
	if not base_texture:
		push_error("Could not load base texture.")
		return

	# 2. Parse the JSON
	var file = FileAccess.open(json_path, FileAccess.READ)
	var json = JSON.new()
	if json.parse(file.get_as_text()) != OK:
		push_error("JSON Parse Error.")
		return
		
	var data = json.get_data().get("spritesheet")

	var anim_library = AnimationLibrary.new()
	
	var data_rows = data.get("rows", [])
	for row in data_rows:
		if row.get("type", "") == "animation":
			var anim: Animation = _parse_single_animation(row, 68, 68, base_texture)
			anim_library.add_animation(_get_name(row), anim)
			
	# Save the entire library into one file
	ResourceSaver.save(anim_library, save_path + "//mech_library.res")
	print("done generating animation")
	
func _ready():
	_run_generation()
