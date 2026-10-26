extends Control
class_name HUD2

@onready var action_menu_ = %ActionGrid
@onready var stats_menu_ = %StatsContainer
@onready var movement_display_ = %Movement
@onready var sub_ability_menu_ = %SubAbilityContainer
@onready var weapon_mount_menu_ = %WeaponMountGrid
@onready var end_turn_button_ = $MarginContainer/VBoxContainer/TopHuD/HBoxContainer/Right/VBoxContainer/EndTurnButton
@onready var info_banner_ = $MarginContainer/VBoxContainer/TopHuD/HBoxContainer/Middle/InfoBanner
@onready var info_banner_timer_ = $MarginContainer/VBoxContainer/TopHuD/HBoxContainer/Middle/InfoBanner/Timer

var current_selected_unit: UnitData
var current_player_turn_: int = -1
var turn_lock_level_: Constants.TurnLockLevel
var local_is_turn_owner_: bool = false

signal reaction_selected(chosen_reaction: ReactionManager.Reaction)

func hide_menus() -> void:
	action_menu_.hide()
	stats_menu_.hide()
	end_turn_button_.hide()
	sub_ability_menu_.hide()

func _ready():
	# Connect to the global signals
	SignalBus.unit_selected.connect(_on_unit_selected)
	SignalBus.unit_deselected.connect(_on_unit_deselected)
	SignalBus.unit_finished_ability.connect(_on_unit_finished_ability)
	SignalBus.start_round.connect(_on_start_round)
	SignalBus.start_turn.connect(_on_start_turn)
	SignalBus.input_authority_changed.connect(_on_input_authority_changed)
	
	# Hide the menu by default
	hide_menus()
	

func _on_input_authority_changed(authorized_player_id: int, lock_level: Constants.TurnLockLevel) -> void:
	turn_lock_level_ = lock_level
	
	# Refresh End Turn button visibility
	end_turn_button_.visible = (local_is_turn_owner_ and turn_lock_level_ == Constants.TurnLockLevel.NONE)
	
	# Hide action menus if actions are locked during a reaction pause
	if turn_lock_level_ != Constants.TurnLockLevel.NONE:
		action_menu_.hide()
		sub_ability_menu_.hide()

func clear_menu(menu: Container):
	for child in menu.get_children():
		child.queue_free()

func update_action_menu(unit: UnitData) -> void:
	clear_menu(action_menu_)
	var abilities : Array[Ability] = unit.get_ability_list()
	for ability in abilities:
		if ability.action_type_ != Ability.ActionType.REACTION:
			var btn = Button.new()
			btn.text = ability.get_ui_name()
			btn.pressed.connect(_on_action_button_pressed.bind(ability, unit))
			action_menu_.add_child(btn)
		

# Call this function when the player clicks on a valid unit
func show_menu_for_unit(unit: UnitData):
	current_selected_unit = unit
	update_stats_menu(unit)
	update_action_menu(unit)
	# ONLY show Action Menu if:
	# 1. Actions are not locked
	# 2. It's the unit owner's active turn
	if local_is_turn_owner_ and turn_lock_level_ == Constants.TurnLockLevel.NONE:
		update_action_menu(unit)
		action_menu_.show()
		stats_menu_.show()
	else:
		action_menu_.hide()
		stats_menu_.hide()

func update_stats_menu(unit: UnitData) -> void:
	movement_display_.text = ("Movement: %s" % unit.get_movement_points())

func show_reaction_menu(reaction_string: String, reactions: Array[String]) -> int:
	# Ensure the action menu hides when the reaction popup opens
	action_menu_.hide()
	sub_ability_menu_.hide()
	return -1
	"""for child in popup_menu_list_.get_children():
			child.queue_free()
			
	for i in range(len(reactions)):
		var btn = Button.new()
		btn.text = reactions[i]
		btn.pressed.connect(_on_reaction_button_pressed.bind(i))
		popup_menu_list_.add_child(btn)
	popup_menu_.show()
	return await reaction_selected"""

func _on_reaction_button_pressed(reaction_id: int):
	#popup_menu_.hide()
	reaction_selected.emit(reaction_id)
	
func _on_start_round(round_number: int) -> void:
	$GeneralButtons/RoundInfo.text = "round: %s" % round_number

func _on_start_turn(player_number: int, peer_id: int) -> void:
	current_player_turn_ = player_number
	local_is_turn_owner_ = (multiplayer.get_unique_id() == peer_id)
	
	if local_is_turn_owner_:
		end_turn_button_.show()
	else:
		end_turn_button_.hide()
	info_banner_timer_.start()
	info_banner_.show()
	info_banner_.text = "Player %s turn" % player_number

func _on_unit_finished_ability(unit: UnitData, ability: Ability):
	update_stats_menu(unit)
	action_menu_.show()
	stats_menu_.show()
	sub_ability_menu_.hide()
	
func _on_unit_selected(unit: UnitData):
	# Only show the menu if the unit belongs to the player
	if unit.own_player_id_ == current_player_turn_:
		show_menu_for_unit(unit)

func _on_unit_deselected(unit: UnitData):
	action_menu_.hide()
	stats_menu_.hide()
	sub_ability_menu_.hide()

func _on_end_turn_button_pressed() -> void:
	action_menu_.hide()
	stats_menu_.hide()
	sub_ability_menu_.hide()
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

func _on_info_banner_timer_timeout() -> void:
	info_banner_.hide()


func _on_pass_button_pressed() -> void:
	popup_menu_.hide()
	reaction_selected.emit(-1)
