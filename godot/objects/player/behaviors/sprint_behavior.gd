class_name SprintBehavior
extends PlayerBehavior

const maybeTransitionFrom: Array[StringName] = [&"crouch", &"squeeze"]
const cannotTransitionFrom: Array[StringName] = [&"crawl", &"climb", &"vault"]
const mutuallyExclusiveWith: Array[StringName] = [&"grab", &"drag", &"film_camera"]

func can_act() -> bool:
    if active: return false
    if (pb.some(cannotTransitionFrom)):
        return false
    elif (pb.some(maybeTransitionFrom)):
        return pb.stand.can_act()
    else:
        return pb.jump.onFloorLastFrame

func start_action() -> void:
    if active: return
    active = true
    if pb.some(maybeTransitionFrom):
        pb.stand.start_action()
    p.try_clear_hover_state()
    pb.stop(mutuallyExclusiveWith)

func process_action(_delta: float) -> void:
    if active && p.moveDir.length_squared() < 0.01 && !Input.is_action_pressed("sprint"):
        stop_action()
