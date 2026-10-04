extends Event
class_name AdvanceTurnEvent

var player_id_: int
var round_num_: int

func _init(player_id: int, round_num: int):
	super._init(EventType.ADVANCE_TURN)
	player_id_ = player_id
	round_num_ = round_num
	
func apply():	
	Level.get_current_level().turn_manager_.end_turn()
	
func to_log() -> String:
	return "player %d end turn, round number %d" % [player_id_, round_num_]
	
func get_sent_packet() -> Array:
	return [type_, player_id_, round_num_]
	
static func from_array(params: Array) -> AdvanceTurnEvent:
	return AdvanceTurnEvent.new(params[0], params[1])
	
