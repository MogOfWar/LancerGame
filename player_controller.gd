@abstract
extends Node
class_name PlayerController

var game_board_: GameBoard
var reaction_manager_: ReactionManager
var player_id_: int = -1

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func _init(logic_node: Node) -> void:
	game_board_ = logic_node.get_node("GameBoard")
	reaction_manager_ = logic_node.get_node("ReactionManager")

@abstract func get_picked_hexes(context: ActionContext, viable_hexes: Array[Vector2i], effect: Effect) -> Vector2i
@abstract func choose_reaction(context: ActionContext, src_ability: Ability, src_effect: Effect, reaction_params: Dictionary, reacting_unit: UnitData, valid_reactions: Array[ReactionManager.Reaction]) -> ReactionManager.Reaction

func execute_ability(ability: Ability, unit: UnitData, sub_name: String) -> void:
	
	var context: ActionContext = ActionContext.new(game_board_, unit, ability, reaction_manager_)
	for effect: Effect in ability.get_effet_group_by_name(sub_name):
		if effect.require_targeting():
			var viable_hexes: Array[Vector2i] = effect.get_viable_targets(context)
			
			var picked_hexes = await get_picked_hexes(context, viable_hexes, effect)
			
			effect.apply(context, picked_hexes)
	game_board_.unit_finished_ability(unit, ability)
	SignalBus.unit_finished_ability.emit(unit)

func execute_reaction(context: ActionContext, src_ability: Ability, src_effect: Effect, reaction_params: Dictionary, reacting_unit: UnitData, valid_reactions: Array[ReactionManager.Reaction]) -> void:
	# Await user selection (UI popup or RPC packet)
	var chosen_reaction: ReactionManager.Reaction = await choose_reaction(context, src_ability, src_effect, reaction_params, reacting_unit, valid_reactions)
	print("player chosen reaction")
	# If player selects "Pass" / "Skip"
	if chosen_reaction == null:
		return
		
	await execute_ability(chosen_reaction.ability, reacting_unit, chosen_reaction.sub_name)
