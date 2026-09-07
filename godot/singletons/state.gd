extends Node

# variable state
var player: Player = null
var loadedLevel: Level = null

func reinit() -> void:
    if loadedLevel != null:
        loadedLevel.free()
    player = null
