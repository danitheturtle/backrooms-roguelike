extends Node

# variable state
var player: Player = null
var levelManager: LevelManager = null
var roomDefinitions: Array[RoomDefinition] = []
var rng: RandomNumberGenerator = null

#State Reinit should only be called when switching save slots
func reinit() -> void:
    if player != null:
        player.free()
        player = null
    if levelManager != null:
        levelManager.free()
        levelManager = null
    if rng != null:
        rng.free()
        rng = null
    if roomDefinitions.size() > 0:
        roomDefinitions = []
