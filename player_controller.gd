@abstract
extends Node
class_name PlayerController

var game_board_: GameBoard

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func _init(logic_node: Node) -> void:
	game_board_ = logic_node.get_node("GameBoard")
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

@abstract func get_picked_hexes(context: ActionContext, viable_hexes: Array[Vector2i]) -> Array[Vector2i]

	

func execute_ability(ability: Ability, unit: UnitData) -> void:
	var context: ActionContext = ActionContext.new(game_board_, unit, ability)
	for effect: Effect in ability.get_effects():
		if effect.require_target():
			var viable_hexes = effect.get_viable_targets(context)
			
			var picked_hexes = await get_picked_hexes(context, viable_hexes)
			
		
