@abstract
extends Node
class_name PlayerController

var game_board_: GameBoard
var reaction_manager_: ReactionManager
var player_id_: int = -1
var level_: Level
var peer_id_: int = -1

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func _init(level: Node, peer_id: int) -> void:
	game_board_ = level.get_node("Logic").get_node("GameBoard")
	reaction_manager_ = level.get_node("Logic").get_node("ReactionManager")
	level_ = level
	peer_id_ = peer_id
	
@abstract func get_picked_hexes(context: ActionContext, viable_hexes: Array[Vector2i], effect: Effect) -> Vector2i
@abstract func choose_reaction(src_ability: Ability, reaction_params: Dictionary, reacting_unit: UnitData, valid_reactions: Array[ReactionManager.Reaction]) -> ReactionManager.Reaction

func execute_ability(ability: Ability, unit: UnitData, sub_name: String) -> void:
	Utils.log_info("unit: %d using ability %s" % [unit.unit_id_, ability.get_ui_name()])
	var context: ActionContext = ActionContext.new(game_board_, unit, ability, reaction_manager_)
	for effect_id in range(ability.get_num_effect_in_group(sub_name)):
		var effect: Effect = ability.get_effect_by_id(sub_name, effect_id)
		if effect.require_targeting():
			var viable_hexes: Array[Vector2i] = effect.get_viable_targets(context)
			
			var picked_hexes = await get_picked_hexes(context, viable_hexes, effect)
			
			var req_id = NetworkManager.get_next_request_id()
			Utils.log_info("unit: %d sending request %d" % [unit.unit_id_, req_id])
			level_.request_apply_effect.rpc_id(1, req_id, unit.unit_id_, ability.id_, sub_name, effect_id, picked_hexes)
			
			while true:
				var res = await level_.effect_execution_finished
				Utils.log_info("unit: %d recieved response %d for req %d" % [unit.unit_id_, res[0], req_id])
				if res[0] == req_id: # Assuming array emitted or direct ID match
					break
					
	game_board_.unit_finished_ability(unit, ability)
	SignalBus.unit_finished_ability.emit(unit, ability)

func execute_reaction(src_ability: Ability, reaction_params: Dictionary, reacting_unit: UnitData, valid_reactions: Array[ReactionManager.Reaction]) -> void:
	# Await user selection (UI popup or RPC packet)
	var chosen_reaction: ReactionManager.Reaction = await choose_reaction(src_ability, reaction_params, reacting_unit, valid_reactions)
	
	# If player selects "Pass" / "Skip"
	if chosen_reaction == null:
		return
		
	await execute_ability(chosen_reaction.ability, reacting_unit, chosen_reaction.sub_name)
