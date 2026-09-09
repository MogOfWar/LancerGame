extends Event
#class mainly for logging has no real effect for now
class_name RollEvent

enum RollType {
	ATTACK
}

const roll_string = {
	RollType.ATTACK : "Attack Roll"
}

var roll_: int
var acc_: int
var target_: int
var roll_type_: RollType

func _init(params: Array):
	super._init(EventType.ROLL)
	roll_ = params[0]
	acc_ = params[1]
	target_ = params[2]
	roll_type_ = params[3]
	
func apply():
	pass
	
func to_log():
	return "%s %s + %s vs %s" % [roll_string[roll_type_], roll_, acc_, target_]
	
func get_sent_packet() -> Array:
	return [type_, roll_, acc_, target_, roll_type_]
	
