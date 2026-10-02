extends Node
class_name ReactionManager

const REACTION_TYPE_KEY = "type"

enum ReactionType {
	ATTACK_DAMAGE,
	MOVE
}

class Reaction:
	var _cond: Callable
	var ability: Ability
	var sub_name: String = "default"
	
	func check(reaction_context: Dictionary) -> bool:
		return _cond.call(reaction_context)

class UnitReaction:
	var unit_: UnitData
	var player_: PlayerController
	var reactions_: Array[Reaction]
	
	func _init(unit: UnitData, player: PlayerController)-> void:
		unit_ = unit
		player_ = player
		reactions_ = []
		
	func add_reaction(reaction: Reaction):
		# might want to check somehow this reaction doesn't already exist
		reactions_.append(reaction)
	
class UnitReactionCollection:
	var collection_: Dictionary[UnitData, UnitReaction]

var reaction_registry: Dictionary[ReactionType, UnitReactionCollection] = {}
var current_player_: Array[int] = []
var _reaction_enabled: bool = true #for debugging can turn off reaction



func register_reaction(type: ReactionType, unit: UnitData, player: PlayerController, reaction: Reaction):
	if not _reaction_enabled:
		return
	var collection: UnitReactionCollection = reaction_registry.get_or_add(type, UnitReactionCollection.new())
	var reacting_unit: UnitReaction = collection.collection_.get_or_add(unit, UnitReaction.new(unit, player))
	reacting_unit.add_reaction(reaction)

func _init():
	SignalBus.start_turn.connect(_on_start_turn)
	
func initalize(enabled = true):
	_reaction_enabled = enabled

func push_new_player(player_id: int) -> void:
	current_player_.push_back(player_id)
	SignalBus.debug_player_reaction.emit(player_id)
	
func pop_player() -> void:
	current_player_.pop_back()
	SignalBus.debug_player_reaction.emit(current_player_[-1])

func handle_reaction(context: ActionContext, effect: Effect, reaction_params: Dictionary) -> void:
	var level: Level = Level.get_current_level()
	var type: ReactionType = reaction_params.get(REACTION_TYPE_KEY, -1)
	if not reaction_registry.has(type):
		return

	var collection: UnitReactionCollection = reaction_registry[type]

	for reacting_unit: UnitReaction in collection.collection_.values():
		var eligible_reactions: Array[int] = []
		var target_unit: UnitData = level.get_unit_by_id(reaction_params["target_unit"])
		# Filter reactions valid right now
		for reaction_id in range(len(reacting_unit.reactions_)):
			var reaction_context = {
				"ability_to_react" : context.ability_,
				"unit_reacting" : reacting_unit.unit_,
				"unit_src_ability": context.source_unit_,
				"unit_dst_ability": target_unit,
				"src_ability_context": context
			}
			var reaction: Reaction = reacting_unit.reactions_[reaction_id]
			if reaction.check(reaction_context):
				eligible_reactions.append(reaction_id)
		
		if eligible_reactions.is_empty():
			continue

		# Await the player's choice and resolution before moving to the next unit
		push_new_player(reacting_unit.player_.player_id_)
		# Assign a unique transaction ID for this specific reaction window
		
		level.flush_events()
		
		var req_id = NetworkManager.get_next_request_id()
		level.request_reaction2.rpc_id(reacting_unit.player_.peer_id_, req_id, type, context.ability_.id_, reaction_params,  reacting_unit.unit_.unit_id_, eligible_reactions)
		while true:
			var response = await Level.get_current_level().reaction_execution_finished
			Utils.log_info("Reaction got response %d for req %d" % [response[0], req_id])
			if response[0] == req_id:
				break
		pop_player()


func get_reaction_by_ids(reaction_type: ReactionType, unit_data: UnitData, reaction_ids: Array[int]) -> Array[Reaction]:
	var ret: Array[Reaction] = []
	var collection: UnitReactionCollection = reaction_registry[reaction_type]
	var reacting_unit: UnitReaction = collection.collection_.get(unit_data, null)
	for reaction_id in reaction_ids:
		ret.append(reacting_unit.reactions_[reaction_id])
	return ret
	

func _on_start_turn(player_id: int, peer_id: int):
	if len(current_player_) > 1:
		Utils.log_error("Reaction stack gone wild")
	current_player_ = [player_id]
