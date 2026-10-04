extends Effect
class_name TerrainEffect

# an ongoing effect that changes how the terrain behaves
# a smoke grande will generate soft cover in an area

enum TerrainEffectType {
	SOFT_COVER = 1 << 0,
	HARD_COVER = 1 << 1,
	LOS_BLOCK = 1 << 2,
	HAZZARD = 1 << 3,
	DIFFCULT_TERRAIN = 1 << 4,
	BLOCK = 1 << 5,
}

# data storage class to pass to game board so it can manipulate and transmit the relvent data
class TerrainHazzard:
	var duration_: int
	var terrain_effect_type_: TerrainEffectType
	
	func _init(duration: int, terrain_effect_type: TerrainEffectType) -> void:
		duration_ = duration
		terrain_effect_type_ = terrain_effect_type
		
	func to_array() -> Array:
		return [duration_, terrain_effect_type_ as int]
		
	static func from_array(params: Array) -> TerrainHazzard:
		return TerrainHazzard.new(params[0], params[1] as TerrainEffectType)

# negative number means indenitenly
@export var duration_: int = -1 
@export var terrain_effect_type_: TerrainEffectType = TerrainEffectType.SOFT_COVER
var hazzard_: TerrainHazzard

func _init() -> void:
	target_type_ = TargetType.HEX
	hazzard_ = TerrainHazzard.new(duration_, terrain_effect_type_)
	
func apply(action_context: ActionContext, target_hex: Vector2i):
	var gb: GameBoard = action_context.game_board_
	var src_unit = action_context.source_unit_
	var affected_hexes: Array[Vector2i] = gb.get_affected_hexes(target_hex, self, src_unit.get_pos_qr())
	Level.get_current_level().event_manager_.handle_event(TerrainEffectEvent.new(affected_hexes, hazzard_))
