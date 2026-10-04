extends Event
class_name TerrainEffectEvent

var hexes_: Array[Vector2i]
var hazzard_: TerrainEffect.TerrainHazzard

func _init(hexes: Array[Vector2i], hazzard: TerrainEffect.TerrainHazzard) -> void:
	super._init(EventType.TERRAIN_HAZZARD)
	hexes_ = hexes
	hazzard_ = hazzard

func apply():
	for hex in hexes_:
		Level.get_current_level().game_board_.add_terrain_effect(hex, hazzard_)

func to_log() -> String:
	var s = "Applying %s to %s" % [hazzard_.terrain_effect_type_, hexes_]
	return s

func get_sent_packet() -> Array:
	return [type_, hexes_, hazzard_.to_array()]
	
