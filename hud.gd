# battle_hud.gd
extends CanvasLayer

@onready var action_menu = $ActionMenu
var current_selected_unit: Node3D

func _ready():
	# Connect to the global signals
	SignalBus.unit_selected.connect(_on_unit_selected)
	SignalBus.unit_cleared.connect(_on_unit_deselected)
	SignalBus.unit_finished_ability.connect(_on_unit_finished_ability)
	
	# Hide the menu by default
	action_menu.hide()

# Call this function when the player clicks on a valid unit
func show_menu_for_unit(unit: Node3D):
	current_selected_unit = unit
	action_menu.show()
	
	# You can even toggle buttons based on the unit's components!
	$ActionMenu/VBoxContainer/AttackButton.visible = true

# Connected via the Godot Inspector to the Button's "pressed" signal
func _on_attack_button_pressed():
	if current_selected_unit:
		# Tell the unit to enter targeting mode
		current_selected_unit.prepare_attack()
		action_menu.hide()
		
func _on_unit_finished_ability(unit: Unit):
	action_menu.show()
	
	
func _on_unit_selected(unit: Node3D):
	# Only show the menu if the unit belongs to the player
	show_menu_for_unit(unit)

func _on_unit_deselected():
	action_menu.hide()
