extends Node

# variable state
var player: Player = null
var levelManager: LevelManager = null

# This is a singleton. Reinit should only be called when 
func reinit() -> void:
    if player != null:
        player.free()
        player = null
    if levelManager != null:
        levelManager.reinit()
        levelManager.free()
        levelManager = null
