extends PlayerController
class_name RemotePlayerController

signal reaction_received(request_id: int, reaction_id: int)

var _next_request_id: int = 0

func get_picked_hexes(context: ActionContext, viable_hexes: Array[Vector2i], effect: Effect) -> Vector2i:
	return Vector2i(-1, -1)

func choose_reaction(context: ActionContext, src_ability: Ability, src_effect: Effect, reaction_params: Dictionary, reacting_unit: UnitData, valid_reactions: Array[ReactionManager.Reaction]) -> ReactionManager.Reaction:
	# Assign a unique transaction ID for this specific reaction window
	var req_id = _next_request_id
	_next_request_id += 1
	
	var reaction_strings: Array[String] = []
	for rxn in valid_reactions:
		reaction_strings.append(rxn.ability.get_ui_name())
		
	var message = "Please select a reaction"
	var level: Level = Level.get_current_level()
	
	# Send the request ID to the client
	level.request_reaction.rpc_id(peer_id_, req_id, message, reaction_strings)
	
	# Loop until we receive the response matching THIS specific request ID
	var chosen_id: int = -1
	while true:
		var response = await reaction_received
		if response[0] == req_id:
			chosen_id = response[1]
			break
			
	return valid_reactions[chosen_id]
