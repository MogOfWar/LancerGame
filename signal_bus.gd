extends Node

# logic signals
signal unit_selected(unit: UnitData)
signal unit_finished_ability(unit: UnitData, ability: Ability)
signal unit_deselected(unit: UnitData)

signal unit_attacking(unit: UnitData, hit: bool)
signal unit_damaged(unit: UnitData, src_unit: UnitData, damage_val: int)
signal unit_died(unit: UnitData)
signal unit_action_selected(unit: UnitData, ability: Ability, sub_name: String)
signal unit_gained_ability(unit: UnitData, ability: Ability)
signal unit_moved(unit: UnitData, src_hex_qry: Vector3, dst_hex_qry: Vector3)
signal unit_weapon_fire(unit: UnitData, target_unit: UnitData)

signal end_turn()
signal start_round(round_number: int)
signal start_turn(player_number: int, peer_id: int)
signal debug_player_reaction(player_id: int) # switch player

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
