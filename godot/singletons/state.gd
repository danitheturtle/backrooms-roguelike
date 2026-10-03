extends Node

# variable state
var player: Player = null
var rng: RandomNumberGenerator = null

#State Reinit should only be called when switching save slots
func reinit() -> void:
    if player != null:
        player.free()
        player = null
    if rng != null:
        rng.free()
        rng = null
