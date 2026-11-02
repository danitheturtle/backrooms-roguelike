class_name StandBehavior
extends PlayerBehavior

const mutuallyExclusiveWith: Array[StringName] = [&"crawl", &"crouch", &"squeeze"]

# Standing is the default player state
func reinit() -> void:
    active = true

func can_act() -> bool:
    return !active && p.can_shape_change()

func start_action() -> void:
    if active: return
    active = true
    pb.stop(mutuallyExclusiveWith)
    p.set_default_positions()
