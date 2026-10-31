class_name SprintBehavior
extends PlayerBehavior

const maybeTransitionFrom: Array[StringName] = [&"crouch", &"squeeze", &"crawl"]
const cannotTransitionFrom: Array[StringName] = [&"climb", &"vault"]
const mutuallyExclusiveWith: Array[StringName] = [&"grab", &"drag", &"film_camera"]

func can_act() -> bool:
    if (pb.some(cannotTransitionFrom)):
        return false
    elif (pb.some(maybeTransitionFrom)):
        return pb.stand.can_act()
    else:
        return pb.jump.onFloorLastFrame

func start_action() -> void:
    if active: return
    active = true
    p.try_clear_hover_state()
    pb.stop(mutuallyExclusiveWith)
