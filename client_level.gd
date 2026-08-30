extends Node

const UnitScene = preload("res://unit.tscn")

var mech_types_ = {}
var units = []
# function to load all abilities at start
func load_unit_types():
	var mechs_to_load = [
		"everest.tres",
	]
	for mtl in mechs_to_load:
		var mech: MechChassis = load(Constants.MECH_PATH + "//" + mtl)
		mech_types_[mech.chassis_name_] = mech
		
# Called when the node enters the scene tree for the first time.

func add_unit(chassis: MechChassis, pos_qr: Vector2i, height: float) -> UnitData:
	var new_unit_data: UnitData = UnitData.new(chassis, pos_qr, height)
	var new_unit_scene: Unit = UnitScene.instantiate()
	new_unit_scene.initalize(new_unit_data)
	$Visuals/Entities.add_child(new_unit_scene)
	return new_unit_data
	
func _ready() -> void:
	load_unit_types()
	# DEBUG just debug stuff for start
	var grid = NoiseGrid.new(10,10, null)
	var unit_a: UnitData = add_unit(mech_types_["Everest"], Vector2i(0,0), 0)
	var unit_b: UnitData = add_unit(mech_types_["Everest"], Vector2i(2,3), 0)
	unit_a.add_weapon(load("res://weapons/assualt_rifle.tres"), MechChassis.MountType.HEAVY)
	%GameBoard.initalize(grid)
	%GameBoard.add_unit(unit_a)
	%GameBoard.add_unit(unit_b)
	%TurnManager.initalize()
	
	var player_1 : HumanPlayerController = HumanPlayerController.new($Logic, $Input/InputManager, $Visuals/TacticalOverlay)
	%TurnManager.add_player(player_1, 0)
	$Visuals/Terrian.initalize(grid)
	# for now init a flat terrain for debug
