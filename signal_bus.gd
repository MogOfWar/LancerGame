extends Node

#emitted when player selects a unit
signal unit_selected(unit)
signal unit_finished_ability(unit)
signal unit_cleared()
signal end_turn()
signal unit_attacking()
signal unit_weapon_selected(unit: Unit, weapon: WeaponType)
signal unit_spawned(unit: Unit)
signal unit_died(unit: Unit)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
