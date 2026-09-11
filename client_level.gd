extends Node
class_name Level

const UnitScene = preload("res://unit.tscn")

var mech_types_ = {}

@onready var turn_manager_: TurnManager = %TurnManager
@onready var game_board_: GameBoard = %GameBoard
@onready var reaction_manager_: ReactionManager = %ReactionManager
@onready var event_manager_: EventManager = %EventManager

var last_sync_point_: int = 0
var units_: Dictionary[int, UnitData] = {}
var peer_id_: int

static var current_level_: Level = null

static func register_level(level: Level):
	current_level_ = level

static func unregister_level():
	current_level_ = null
	
static func get_current_level() -> Level:
	return current_level_

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
	units_[new_unit_data.unit_id_] = new_unit_data
	return new_unit_data

func _on_unit_gained_ability(unit: UnitData, ability: Ability) -> void:
	if ability.action_type_ == Ability.ActionType.REACTION:
		var reaction: ReactionManager.Reaction = ability.get_reaction()
		var reaction_type: ReactionManager.ReactionType = ability.get_reaction_type()
		reaction_manager_.register_reaction(ability.get_reaction_type(), unit, turn_manager_.get_player_by_id(unit.own_player_id_), ability.get_reaction())

func _ready() -> void:
	register_level(self)
	# register signals first 
	SignalBus.unit_gained_ability.connect(_on_unit_gained_ability)
	var args = OS.get_cmdline_args()
	var is_client: bool = "--client" in args
	
	if is_client:
		await NetworkManager.join_game("127.0.0.1")
	else: #host
		await NetworkManager.host_game(2)
	
	# Halt execution until ALL connected clients reach this point
	await NetworkManager.reach_barrier("level_init")
	peer_id_ = multiplayer.get_unique_id()
	var player_1 : PlayerController = null
	var player_2 : PlayerController = null
	
	if is_client:
		player_2 = HumanPlayerController.new(self, multiplayer.get_unique_id(), $Input/InputManager, $Visuals/TacticalOverlay, $UI/HUD, )
		player_1 = RemotePlayerController.new(self, -1)
		turn_manager_.add_player(player_1, 0)
		turn_manager_.add_player(player_2, 0)
	else:
		player_1 = HumanPlayerController.new(self, multiplayer.get_unique_id(), $Input/InputManager, $Visuals/TacticalOverlay, $UI/HUD)
		player_2 = RemotePlayerController.new(self, multiplayer.get_peers()[0])
		turn_manager_.add_player(player_1, 0)
		turn_manager_.add_player(player_2, 0)
	
	var grid : GridData = load("res://art/demo.tres") as GridData# NoiseGrid.new(10,10, null)
	grid.init_from_cells(grid.cells_, grid.width_, grid.height_)
	turn_manager_.initalize()
	game_board_.initalize(grid)
	reaction_manager_.initalize(false)
	
	
	
	load_unit_types()
	# DEBUG just debug stuff for start
	var unit_a: UnitData = add_unit(mech_types_["Everest"], Vector2i(0,0), grid.get_height_from_qr(Vector2i(0,0)), player_1)
	var unit_b: UnitData = add_unit(mech_types_["Everest"], Vector2i(-2,5), grid.get_height_from_qr(Vector2i(-2,5)), player_2)
	unit_a.add_weapon(load("res://weapons/assualt_rifle.tres"), MechChassis.MountType.HEAVY)
	
	game_board_.add_unit(unit_a)
	game_board_.add_unit(unit_b)
	
	
	
	$Visuals/Terrian.initalize(grid)
	# for now init a flat terrain for debug
	
	turn_manager_.start_battle()

func get_unit_by_id(unit_id: int) -> UnitData:
	return units_[unit_id]
	
@rpc("any_peer", "call_local", "reliable")
func request_apply_effect(unit_id: int, ability_id: int, group_name: String, effect_id: int, target_hex) -> void:
	if not multiplayer.is_server():
		return

	var sender_id = multiplayer.get_remote_sender_id()
	var unit: UnitData = get_unit_by_id(unit_id)
	var ability: Ability = unit.get_ability_by_id(ability_id)

	# 1. Verify player ownership and turn permissions
	#if not is_peer_turn(sender_id, unit):
	#	return

	# 2. Authoritative check on the server's state
	if not game_board_.is_ability_executable(unit, ability):
		# Optional: Send a sync RPC back to client if state is desynced
		return
	
	var effect: Effect = ability.get_effect_by_id(group_name, effect_id)
	var action_context: ActionContext = ActionContext.new(game_board_, unit, ability, reaction_manager_)
	effect.apply(action_context, target_hex)

@rpc("authority", "call_remote", "reliable")
func sync_events(event_data: Array):
	for packet in event_data:
		var new_event: Event
		var type: Event.EventType = packet[0]
		if type == Event.EventType.MOVE:
			new_event = MoveEvent.new(packet.slice(1, len(packet)))
		elif type == Event.EventType.WEAPON_FIRE:
			new_event = WeaponFireEvent.new(packet.slice(1, len(packet)))
		elif type == Event.EventType.ROLL:
			new_event = RollEvent.new(packet.slice(1, len(packet)))
		elif type == Event.EventType.DAMAGE:
			new_event = DamageEvent.new(packet.slice(1, len(packet)))
		elif type == Event.EventType.STATUS:
			new_event = StatusEvent.new(packet[1], StatusCondition.from_array(packet[2]))
		else:
			Utils.log_error("Unhandled sync event")
		event_manager_.handle_event(new_event)

@rpc("authority", "call_local", "reliable")
func request_reaction(req_id:int, message: String, reaction_strings: Array[String]):
	var player: HumanPlayerController = turn_manager_.get_player_by_peer_id(multiplayer.get_unique_id()) as HumanPlayerController
	var reaction_id: int = await player.user_choose_reaction(message, reaction_strings)
	recieve_reaction.rpc_id(1, req_id, reaction_id)
	
@rpc("any_peer", "call_local", "reliable")
func recieve_reaction(req_id: int, reaction_id: int):
	if not multiplayer.is_server():
		return
		
	var sender_id = multiplayer.get_remote_sender_id()
	var player: RemotePlayerController = turn_manager_.get_player_by_peer_id(sender_id) as RemotePlayerController
	player.reaction_received.emit(req_id, reaction_id)
	
func _process(delta: float) -> void:
	if len(event_manager_.events_) > last_sync_point_:
		var sent_data = []
		for event in event_manager_.events_.slice(last_sync_point_, len(event_manager_.events_)):
			var serialzied_event = event.get_sent_packet()
			sent_data.append(serialzied_event)
		sync_events.rpc(sent_data)
	last_sync_point_ = len(event_manager_.events_)
