class_name SqueezeBehavior
extends PlayerBehavior

const cannotTransitionFrom: Array[StringName] = [&"crawl", &"vault", &"crouch", &"climb", &"drag", &"grab"]

func can_act() -> bool:
    if (pb.none(cannotTransitionFrom)):
        return p.onFloorLastFrame
    elif (p.b.crouch.active):
        return p.b.stand.can_act()
    else:
        return false

func start_action() -> void:
    if active: return
    pb.stand.start_action()
    active = true
    pb.sprint.stop_action()
    p.try_clear_hover_state()
    p.playerShape.radius = p.SQUEEZE_RADIUS
    pb.flashlight.light.position.x = 0
