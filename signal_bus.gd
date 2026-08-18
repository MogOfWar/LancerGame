extends Node

# logic signals
signal unit_selected(unit)
signal unit_finished_ability(unit)
signal unit_cleared()
signal end_turn()
signal unit_attacking()
signal unit_weapon_selected(unit: Unit, weapon: WeaponType)
signal unit_spawned(unit: Unit)
signal unit_died(unit: Unit)
signal unit_move_button_pressed(unit: Unit)

# input/ui signals
signal ui_hex_hovered(hovered_hex: Vector2i)
signal ui_hex_selected(selected_hex: Vector2i)
signal ui_draw_highlights(hexes_to_draw)

# tactical overlay signals
signal tol_path_calculated(hex_positions: Array[Vector3])
signal tol_path_cleared()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
