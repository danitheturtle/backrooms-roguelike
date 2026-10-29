class_name GrabBehavior
extends PlayerBehavior

const MAX_GRAB_MASS: float = 15.0
const cannotTransitionFrom: Array[StringName] = [&"drag", &"jump", &"vault", &"crouch", &"crawl", &"squeeze", &"sprint", &"climb", &"film_camera"]

func can_act() -> bool:
    if (!active && pb.none(cannotTransitionFrom) && p.onFloorLastFrame):
        if (p.objectInReachRef != null && p.objectInReachRef.mass > MAX_GRAB_MASS):
            return false
        else:
            return true
    else:
        return false

func start_action() -> void:
    if active: return
    p.objectInReachRef.on_hold()
    p.grabArm.spring_length = p.objectInReachRef.heldDistance
    p.grabArm.shape.radius = p.objectInReachRef.heldCollisionRadius
    # causes visual bug as spring arm rapidly shifts if we don't defer
    call_deferred("_handle_start_deferred")
func _handle_start_deferred():
    active = true
    p.heldObjectRef = p.objectInReachRef
    p.heldObjectRef.clear_hover_material()

func process_action(_delta: float) -> void:
    # account for objects not moved from their default origin
    var heldObjectOrigin = p.heldObjectRef.get_node_or_null("GrabOrigin")
    var fromPos = p.heldObjectRef.global_position if heldObjectOrigin == null else p.heldObjectOrigin.global_position
    var toPos = p.grabAnchor.global_position
    p.heldObjectRef.linear_velocity = (toPos - fromPos) / _delta + p.velocity
    p.heldObjectRef.angular_velocity *= 0.1

func stop_action() -> void:
    if !active: return
    active = false
    p.heldObjectRef.on_drop()
    p.heldObjectRef = null
    p.grabArm.spring_length = p.grabArmLength
    p.grabArm.shape.radius = p.grabArmShapeRadius
    pb.stand.start_action()
