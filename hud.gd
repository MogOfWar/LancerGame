# battle_hud.gd
extends CanvasLayer

@onready var action_menu = $ActionMenu
@onready var weapons_menu_ = $WeaponsMenu
@onready var weapons_list_ = $WeaponsMenu/HBoxContainer/WeaponsList
var current_selected_unit: Node3D

func _ready():
	# Connect to the global signals
	SignalBus.unit_selected.connect(_on_unit_selected)
	SignalBus.unit_cleared.connect(_on_unit_deselected)
	SignalBus.unit_finished_ability.connect(_on_unit_finished_ability)
	
	# Hide the menu by default
	action_menu.hide()
	weapons_menu_.hide()

# Call this function when the player clicks on a valid unit
func show_menu_for_unit(unit: Node3D):
	current_selected_unit = unit
	action_menu.show()

# Connected via the Godot Inspector to the Button's "pressed" signal
func _on_attack_button_pressed():
	if current_selected_unit:
		# Tell the unit to enter targeting mode
		
		action_menu.hide()
		weapons_menu_.show()
		for child in weapons_list_.get_children():
			child.queue_free()
			
		for weapon_ui in current_selected_unit.get_mounts():
			var btn = Button.new()
			btn.text = weapon_ui.get_ui_string()
			
			# Connect the button and pass the SPECIFIC weapon to the function
			btn.pressed.connect(_on_weapon_selected.bind(weapon_ui))
			
			weapons_list_.add_child(btn)
		
func _on_unit_finished_ability(unit: Unit):
	action_menu.show()
	weapons_menu_.hide()
	
func _on_weapon_selected(w: Unit.WeaponInstance):
	current_selected_unit.prepare_attack(w)
	SignalBus.unit_weapon_selected.emit(current_selected_unit, w.weapon_)
	
func _on_unit_selected(unit: Node3D):
	# Only show the menu if the unit belongs to the player
	show_menu_for_unit(unit)

func _on_unit_deselected():
	action_menu.hide()


func _on_end_turn_button_pressed() -> void:
	action_menu.hide()
	SignalBus.end_turn.emit()
	
