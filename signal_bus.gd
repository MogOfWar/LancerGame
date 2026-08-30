extends Node

# logic signals
signal unit_selected(unit: UnitData)
signal unit_finished_ability(unit)
signal unit_cleared()
signal end_turn()
signal unit_attacking(unit: UnitData, hit: bool)
signal unit_damaged(unit: UnitData, damage_val: int)
signal unit_died(unit: UnitData)
signal unit_action_selected(unit: UnitData, ability: Ability, sub_name: String)



# visual signals
signal vis_unit_spawned(unit: Unit)
signal vis_unit_died(unit: Unit)

# input/ui signals
signal ui_update_health_width(unit_visual: Unit)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
