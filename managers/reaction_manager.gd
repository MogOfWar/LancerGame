extends Node
class_name ReactionManager

const REACTION_TYPE_KEY = "type"

enum ReactionType {
	ATTACK_DAMAGE
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
	var type_: ReactionType = reaction_params.get(REACTION_TYPE_KEY, -1)
	if not reaction_registry.has(type_):
		return

	var collection: UnitReactionCollection = reaction_registry[type_]

	for reacting_unit: UnitReaction in collection.collection_.values():
		var eligible_reactions: Array[Reaction] = []
		
		# Filter reactions valid right now
		for reaction: Reaction in reacting_unit.reactions_:
			var reaction_context = {
				"ability_to_react" : context.ability_,
				"unit_reacting" : reacting_unit.unit_,
				"unit_src_ability": context.source_unit_,
				"unit_dst_ability": reaction_params["target_unit"],
				"src_ability_context": context
			}
			if reaction.check(reaction_context):
				eligible_reactions.append(reaction)
		
		if eligible_reactions.is_empty():
			continue

		# Await the player's choice and resolution before moving to the next unit
		print("waiting for player reaction")
		push_new_player(reacting_unit.player_.player_id_)
		await reacting_unit.player_.execute_reaction(
			context, context.ability_, effect, reaction_params, reacting_unit.unit_, eligible_reactions
		)
		pop_player()
		print("player executed reaction")

func _on_start_turn(player_id: int):
	if len(current_player_) > 1:
		Utils.log_error("Reaction stack gone wild")
	current_player_ = [player_id]
