class_name DragBehavior
extends PlayerBehavior

const MAX_DRAG_MASS: float = 150.0

const cannotTransitionFrom: Array[StringName] = [&"grab", &"jump", &"vault", &"crouch", &"crawl", &"squeeze", &"sprint", &"climb", &"film_camera"]

func can_act() -> bool:
    if (!active && pb.none(cannotTransitionFrom) && p.onFloorLastFrame):
        if (p.objectInReachRef != null && p.objectInReachRef.mass > MAX_DRAG_MASS):
            return false
        else:
            return true
    else:
        return false

func start_action() -> void:
    if active: return
    active = true
    p.objectInReachRef.on_hold()
    p.draggedPoint = p.objectInReachRef.to_local(p.grabAnchor.global_position)
    p.heldObjectRef = p.objectInReachRef
    p.heldObjectRef.clear_hover_material()

func stop_action() -> void:
    if !active: return
    active = false
    p.heldObjectRef.on_drop()
    p.heldObjectRef = null
    p.grabArm.spring_length = p.grabArmLength
    p.grabArm.shape.radius = p.grabArmShapeRadius
    pb.stand.start_action()
