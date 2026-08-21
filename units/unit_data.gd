extends RefCounted
class_name UnitData

var unit_: Unit
var unit_id_: int = -1
var abilities_ = []
func _init(unit: Unit, unit_id: int) -> void:
	unit_ = unit
	unit_id_ = unit_id
	abilities_.append(MoveAbility.new())
	
func get_ability_list() -> Array[Ability]:
	return abilities_
	
func get_movement_points() -> int:
	return unit_.move_points
	
