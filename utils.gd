extends Node

static func log_error(str: String, to_file: bool = false) -> void:
	var stack = get_stack()
	if stack.is_empty() or len(stack) == 1:
		if str.is_empty():
			print("Error")
		else:
			print("Error: %s" % str)
	else:
		var calling_frame = stack[1]
		var file = calling_frame.source
		var func_name = calling_frame.function
		print("Error[%s,%s] %s" % [file, func_name, str])

static func log_combat(time: int, str: String) -> void:
	print("Combat[%s] %s" % [time, str])
	
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
