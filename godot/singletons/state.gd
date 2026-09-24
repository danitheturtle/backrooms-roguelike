extends Node
# global constants
const VOXEL: float = 0.5
const HALF_VOXEL: float = VOXEL / 2.0
const QUARTER_VOXEL: float = VOXEL / 4.0
# variable state
var player: Player = null
var levelManager: LevelManager = null
var rng: RandomNumberGenerator = null

#State Reinit should only be called when switching save slots
func reinit() -> void:
    if player != null:
        player.free()
        player = null
    if levelManager != null:
        levelManager.free()
        levelManager = null
