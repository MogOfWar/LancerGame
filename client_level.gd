extends Node

const UnitScene = preload("res://unit.tscn")

var mech_types_ = {}

@onready var turn_manager_: TurnManager = %TurnManager
@onready var game_board_: GameBoard = %GameBoard
@onready var reaction_manager_: ReactionManager = %ReactionManager


# function to load all abilities at start
func load_unit_types():
	var mechs_to_load = [
		"everest.tres",
	]
	for mtl in mechs_to_load:
		var mech: MechChassis = load(Constants.MECH_PATH + "//" + mtl)
		mech_types_[mech.chassis_name_] = mech
		
# Called when the node enters the scene tree for the first time.

func add_unit(chassis: MechChassis, pos_qr: Vector2i, height: float, own_player: PlayerController) -> UnitData:
	var new_unit_data: UnitData = UnitData.new(chassis, pos_qr, height, own_player)
	var new_unit_scene: Unit = UnitScene.instantiate()
	new_unit_scene.initalize(new_unit_data)
	$Visuals/Entities.add_child(new_unit_scene)
	return new_unit_data

func _on_unit_gained_ability(unit: UnitData, ability: Ability) -> void:
	if ability.action_type_ == Ability.ActionType.REACTION:
		var reaction: ReactionManager.Reaction = ability.get_reaction()
		var reaction_type: ReactionManager.ReactionType = ability.get_reaction_type()
		reaction_manager_.register_reaction(ability.get_reaction_type(), unit, turn_manager_.get_player_by_id(unit.own_player_id_), ability.get_reaction())

func _ready() -> void:
	# register signals first 
	SignalBus.unit_gained_ability.connect(_on_unit_gained_ability)
	
	
	var grid = NoiseGrid.new(10,10, null)
	turn_manager_.initalize()
	game_board_.initalize(grid)
	reaction_manager_.initalize(false)
	
	var player_1 : HumanPlayerController = HumanPlayerController.new($Logic, $Input/InputManager, $Visuals/TacticalOverlay, $UI/HUD)
	var player_2 : HumanPlayerController = HumanPlayerController.new($Logic, $Input/InputManager, $Visuals/TacticalOverlay, $UI/HUD)
	turn_manager_.add_player(player_1, 0)
	turn_manager_.add_player(player_2, 0)
	
	load_unit_types()
	# DEBUG just debug stuff for start
	var unit_a: UnitData = add_unit(mech_types_["Everest"], Vector2i(0,0), 0, player_1)
	var unit_b: UnitData = add_unit(mech_types_["Everest"], Vector2i(-2,5), 0, player_2)
	unit_a.add_weapon(load("res://weapons/assualt_rifle.tres"), MechChassis.MountType.HEAVY)
	
	game_board_.add_unit(unit_a)
	game_board_.add_unit(unit_b)
	
	
	
	$Visuals/Terrian.initalize(grid)
	# for now init a flat terrain for debug
	
	turn_manager_.start_battle()
