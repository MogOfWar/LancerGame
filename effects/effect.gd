@abstract 
extends Resource
class_name Effect

enum TargetType {
	SELF,
	HEX,
	ANY,
	ENEMY,
	NONE,
}

enum TargetMode {Single, Blast, Cone, Burst, Line}

@export var target_type_: TargetType = TargetType.NONE
@export var target_mode_: TargetMode = TargetMode.Single
@export var target_mode_radius_: int = 0
@export var range_: int = 0

@abstract func apply(action_context: ActionContext, target_hex: Vector2i)

func get_server_packet() -> Effect:
	return self
		
func require_targeting() -> bool:
	return target_type_ != TargetType.NONE

func get_affected_units(affected_hexes: Array[Vector2i]) -> Array[UnitData]:
	var gb: GameBoard = Level.get_current_level().game_board_
	var affected_units: Array[UnitData] = []
	for hex in affected_hexes:
		var data = gb.get_hex_data(hex)
		if data.unit != null and data.unit not in affected_units:
			affected_units.append(data.unit)
	return affected_units
	
# return viable hexes in axial coordinates
# specialized effects can override this function to supply their own viable picks like move
func get_viable_targets(context: ActionContext) -> Array[Vector2i]:
	match target_type_:
		TargetType.ENEMY:
			return context.game_board_.get_units_in_range(context.source_unit_.get_pos_qr(), range_)
		TargetType.SELF:
			return [context.source_unit_.get_pos_qr()]
		TargetType.HEX:
			return context.game_board_.get_hexes_qr_in_range(context.source_unit_.get_pos_qr(), range_)	
		TargetType.ANY:
			return context.game_board_.get_hexes_qr_in_range(context.source_unit_.get_pos_qr(), range_)
		TargetType.NONE:
			Utils.log_error("Invalid target type for effect")
			return []
	return []
