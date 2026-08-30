# battle_hud.gd
extends CanvasLayer

@onready var action_menu = $ActionMenu
@onready var action_menu_container_ = $ActionMenu/HBoxContainer
@onready var sub_ability_menu_ = $SubAbilityMenu
@onready var sub_ability_list_ = $SubAbilityMenu/HBoxContainer/SubAbilityList
@onready var stats_menu_ = $Stats
@onready var actions_display_ = $Stats/HBoxContainer/Actions
@onready var movement_display_ = $Stats/HBoxContainer/Movement
var current_selected_unit: UnitData

func _ready():
	# Connect to the global signals
	SignalBus.unit_selected.connect(_on_unit_selected)
	SignalBus.unit_cleared.connect(_on_unit_deselected)
	SignalBus.unit_finished_ability.connect(_on_unit_finished_ability)
	
	# Hide the menu by default
	action_menu.hide()
	sub_ability_menu_.hide()
	stats_menu_.hide()

func clear_menu(menu: Container):
	for child in menu.get_children():
		child.queue_free()

func update_action_menu(unit: UnitData) -> void:
	clear_menu(action_menu_container_)
	var abilities : Array[Ability] = unit.get_ability_list()
	for ability in abilities:
		var btn = Button.new()
		btn.text = ability.get_ui_name()
		btn.pressed.connect(_on_action_button_pressed.bind(ability, unit))
		action_menu_container_.add_child(btn)
		

# Call this function when the player clicks on a valid unit
func show_menu_for_unit(unit: UnitData):
	current_selected_unit = unit
	update_stats_menu(unit)
	update_action_menu(unit)
	action_menu.show()
	stats_menu_.show()

func update_stats_menu(unit: UnitData) -> void:
	actions_display_.text = ("Actions: None")
	movement_display_.text = ("Movement: %s" % unit.get_movement_points())


func _on_unit_finished_ability(unit: UnitData):
	update_stats_menu(unit)
	action_menu.show()
	stats_menu_.show()
	sub_ability_menu_.hide()
	
func _on_unit_selected(unit: UnitData):
	# Only show the menu if the unit belongs to the player
	show_menu_for_unit(unit)

func _on_unit_deselected():
	action_menu.hide()
	stats_menu_.hide()

func _on_end_turn_button_pressed() -> void:
	action_menu.hide()
	SignalBus.end_turn.emit()
	
func _on_action_button_pressed(ability: Ability, unit: UnitData) -> void:
	var sub_group_names: Array[String] = ability.get_effect_groups_names()
	if !ability.has_optional_abilities():
		SignalBus.unit_action_selected.emit(unit, ability, sub_group_names[0])
	else:
		sub_ability_menu_.show()
		for child in sub_ability_list_.get_children():
			child.queue_free()
		for effect_group_name in sub_group_names:
			var btn = Button.new()
			btn.text = effect_group_name
			btn.pressed.connect(_on_sub_action_button_pressed.bind(ability, unit, effect_group_name))
			sub_ability_list_.add_child(btn)
			
func _on_sub_action_button_pressed(ability: Ability, unit: UnitData, sub_key: String) -> void:
	SignalBus.unit_action_selected.emit(unit, ability, sub_key)
