class_name SprintBehavior
extends PlayerBehavior

const cannotTransitionFrom: Array[StringName] = [&"squeeze", &"crawl", &"climb"]
const mutuallyExclusiveWith: Array[StringName] = [&"grab", &"drag", &"film_camera"]

func can_act() -> bool:
    if (pb.some(cannotTransitionFrom)):
        return false
    elif (pb.crouch.active):
        return pb.stand.can_act()
    elif (!pb.vault.active):
        return p.onFloorLastFrame
    return false

func start_action() -> void:
    if active: return
    active = true
    p.try_clear_hover_state()
    pb.stop(mutuallyExclusiveWith)
