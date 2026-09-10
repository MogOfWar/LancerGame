extends Node
class_name VisualManager

var queue_: VisualQueue = VisualQueue.new()

class VisualRegistry:
	var registry_: Dictionary = {}
	static var _mutex: Mutex = Mutex.new()
	func register(src, dst) -> void:
		_mutex.lock()
		if registry_.has(src):
			Utils.log_error("registry already has %s" % src)
		else:
			registry_[src] = dst
		_mutex.unlock()
	
	func unregister(src) -> void:
		_mutex.lock()
		registry_.erase(src)
		_mutex.unlock()
		
	func get_mapping(src):
		_mutex.lock()
		var ret = registry_.get_or_add(src, null)
		_mutex.unlock()
		return ret
		
static var visual_registry: VisualRegistry = VisualRegistry.new()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	SignalBus.unit_damaged.connect(_on_unit_damaged)
	SignalBus.vis_unit_spawned.connect(_on_vis_unit_spawned)
	SignalBus.unit_moved.connect(_on_unit_moved)
	SignalBus.unit_weapon_fire.connect(_on_unit_weapon_fire)
	pass # Replace with function body.


func _on_unit_weapon_fire(attacking_unit: UnitData, target_unit: UnitData) -> void:
	var visual_unit: Unit = visual_registry.get_mapping(attacking_unit)
	var target_vis_unit: Unit = visual_registry.get_mapping(target_unit)
	queue_.add_event(WeaponFireVisualEvent.new(visual_unit, target_vis_unit.global_position))
	
func _on_vis_unit_spawned(unit: Unit) -> void:
	visual_registry.register(unit.unit_data_, unit)
	
func _on_vis_unit_died(unit: Unit) -> void:
	visual_registry.unregister(unit)

func _on_unit_damaged(unit: UnitData, src_unit: UnitData, damage_val: int) -> void:
	var visual_unit: Unit = visual_registry.get_mapping(unit)
	var src_visual_unit: Unit = visual_registry.get_mapping(src_unit)
	if not visual_unit:
		Utils.log_error("error")
		return
	var float_text_params = {
		"global_position" : visual_unit.global_position,
		"text_to_show" : str(damage_val)
	}
	var vfx_call: Callable = VFXManager.spawn_hit_spark.bind(visual_unit.global_position + Vector3(0,1,0), visual_unit.global_position - src_visual_unit.global_position)
	queue_.add_event(VFXVisualEvent.new(vfx_call))
	queue_.add_event(FloatingTextVisualEvent.new(float_text_params))
	queue_.add_event(UpdateWidgetVisualEvent.new(visual_unit))
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func _on_unit_moved(unit: UnitData, src_hex_qry: Vector3, dst_hex_qry: Vector3):
	var vis_unit: Unit = visual_registry.get_mapping(unit)
	var move_params = {
		"unit": vis_unit,
		"src": src_hex_qry,
		"dst": dst_hex_qry
	}
	queue_.add_event(MoveVisualEvent.new(move_params))
