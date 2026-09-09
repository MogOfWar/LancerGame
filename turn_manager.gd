extends Node
class_name TurnManager

var num_players_: int = 0
var current_player_turn_: int = 0
var current_state_ = 0
var players_: Dictionary[int, PlayerController] = {}
var players_faction_map_ = {}
var round_number_ = 0

func _ready() -> void:
	SignalBus.end_turn.connect(_on_end_turn)
	pass # Replace with function body.

func initalize() -> void:
	pass

func add_player(player: PlayerController, faction: int) -> void:
	player.player_id_ = num_players_
	players_[player.player_id_] = player
	num_players_ += 1
	add_child(player)
	
func get_player_by_id(id: int) -> PlayerController:
	if players_.has(id):
		return players_[id]
	else:
		Utils.log_error("Invalid player id")
		return null
	
# should be called after players were added
func start_battle():
	start_round()
	start_turn()

func start_round():
	current_player_turn_ = 0
	SignalBus.start_round.emit.call_deferred(round_number_)

func end_round():
	round_number_ += 1
	#do end of round stuff
	start_round()

func start_turn():
	var player: PlayerController = get_player_by_id(current_player_turn_)
	SignalBus.start_turn.emit.call_deferred(current_player_turn_, player.peer_id_)


func end_turn():
	current_player_turn_ = current_player_turn_ + 1 
	if current_player_turn_ == num_players_:
		#end round
		end_round()
	_advance_turn.rpc(current_player_turn_, round_number_)

# seperate function because clients might not hold right number of players
@rpc("authority", "call_local", "reliable")
func _advance_turn(current_player, round_number):
	current_player_turn_ = current_player
	round_number_ = round_number
	start_turn()
	
@rpc("any_peer", "call_local", "reliable")
func try_to_end_turn():
	if not multiplayer.is_server():
		return
		
	var sender_id = multiplayer.get_remote_sender_id()
	var active_player = get_player_by_id(current_player_turn_)
	
	# Verify sender actually owns the active player controller
	if active_player and active_player.peer_id_ == sender_id:
		end_turn()
	else:
		Utils.log_error("Unauthorized end turn request from peer: %d" % sender_id)

func _on_end_turn() -> void:
	try_to_end_turn.rpc_id(1)
