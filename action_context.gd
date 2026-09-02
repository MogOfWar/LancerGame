extends RefCounted

class_name ActionContext

var game_board_ : GameBoard
var ability_ : Ability
var source_unit_ : UnitData
var reaction_manager_: ReactionManager

func _init(game_board: GameBoard, source_unit: UnitData, parent_ability: Ability, reaction_manager: ReactionManager):
	game_board_ = game_board
	ability_ = parent_ability
	source_unit_ = source_unit
	reaction_manager_ = reaction_manager
