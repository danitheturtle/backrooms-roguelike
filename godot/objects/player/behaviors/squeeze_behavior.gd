class_name SqueezeBehavior
extends PlayerBehavior

const cannotTransitionFrom: Array[StringName] = [&"crawl", &"vault", &"climb", &"drag", &"grab"]
const mutuallyExclusiveWith: Array[StringName] = [&"stand", &"sprint", &"crouch"]

func can_act() -> bool:
    if active: return false
    if (pb.none(cannotTransitionFrom) && !pb.crouch.active):
        return pb.jump.onFloorLastFrame
    elif (pb.crouch.active):
        return p.can_shape_change()
    else:
        return false

func start_action() -> void:
    if active: return
    active = true
    pb.stop(mutuallyExclusiveWith)
    pb.target.stop_if_target_is_holdable()
    set_positions()

func set_positions() -> void:
    p.set_default_positions()
    p.playerShape.radius = p.SQUEEZE_RADIUS
    pb.flashlight.light.position.x = 0
