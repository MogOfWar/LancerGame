extends Node

var num_players_: int = 0
var current_player_turn_: int = 0
var current_state_ = 0
var players_: Array[PlayerController] = []
var players_faction_map_ = {}

func _ready() -> void:
	pass # Replace with function body.

func initalize() -> void:
	pass

func add_player(player: PlayerController, faction: int) -> void:
	players_.append(player)
	num_players_ += 1
	add_child(player)
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
