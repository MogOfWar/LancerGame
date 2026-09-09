@abstract
extends Resource
class_name Event

enum EventType {
	MOVE,
	WEAPON_FIRE,
	ROLL,
	DAMAGE
}

"const type_to_class_map = {
	EventType.MOVE : MoveEvent,
	EventType.WEAPON_FIRE : WeaponFireEvent,
	EventType.ROLL : RollEvent,
	EventType.DAMAGE : DamageEvent
	
	
}"

var type_: EventType

func _init(type: EventType):
	type_ = type

@abstract func apply()
@abstract func to_log() -> String
@abstract func get_sent_packet() -> Array
