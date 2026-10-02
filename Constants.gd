extends Resource
class_name Constants

const VFX_PATH: String = "res://vfx"
const MECH_PATH: String = "res://mechs"

enum DamageType {
	KINETIC
}

enum TurnLockLevel {
	NONE = 0,            # Active turn: full control (Action Menu, Moving, End Turn)
	ACTIONS_LOCKED = 1,  # Out of turn / Interrupted: Inspect board/units, read stats, move camera
	FULL_LOCK = 2        # Animations/Visual Queue: Block all clicks and UI interaction
}
