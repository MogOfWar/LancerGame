extends Node

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	%GameBoard.initalize()
	%TurnManager.initalize()
	
	var player_1 : HumanPlayerController = HumanPlayerController.new($Logic, $Input/InputManager, $Visuals/TacticalOverlay)
	%TurnManager.add_player(player_1, 0)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
