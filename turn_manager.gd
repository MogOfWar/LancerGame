extends Node
class_name TurnManager

var num_players_: int = 0
var current_player_turn_: int = 0
var current_state_ = 0
var players_: Array[PlayerController] = []
var players_faction_map_ = {}
var round_number_ = 0

func _ready() -> void:
	SignalBus.end_turn.connect(_on_end_turn)
	pass # Replace with function body.

func initalize() -> void:
	pass

func add_player(player: PlayerController, faction: int) -> void:
	players_.append(player)
	player.player_id_ = num_players_
	num_players_ += 1
	add_child(player)
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
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
	SignalBus.start_turn.emit.call_deferred(current_player_turn_)

func _on_end_turn() -> void:
	current_player_turn_ = current_player_turn_ + 1 
	if current_player_turn_ == num_players_:
		#end round
		end_round()
	start_turn()
