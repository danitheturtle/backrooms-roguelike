class_name GrabBehavior
extends PlayerBehavior

const cannotTransitionFrom: Array[StringName] = [&"drag", &"jump", &"vault", &"crouch", &"crawl", &"squeeze", &"sprint", &"climb", &"film_camera"]

var grabbedRef: Holdable
var justGrabbed: bool

func get_active() -> bool: return grabbedRef != null

func set_active(_nextVal: bool) -> void: pass

func reinit() -> void:
    if active:
        grabbedRef.on_drop()
        grabbedRef = null

func can_act() -> bool:
    if (!active && pb.none(cannotTransitionFrom) && pb.jump.onFloorLastFrame):
        return not (pb.target.ref is Holdable && pb.target.ref.mass > p.MAX_GRAB_MASS)
    else:
        return false

func start_action() -> void:
    if active: return
    pb.target.ref.on_hold()
    p.grabArm.spring_length = pb.target.ref.heldDistance
    p.grabArm.shape.radius = pb.target.ref.heldCollisionRadius
    # causes visual bug as spring arm rapidly shifts if we don't wait a frame
    await p.get_tree().process_frame
    grabbedRef = pb.target.ref
    justGrabbed = true
    pb.target.stop_action()
    # always rotate on pickup
    pb.rotate.start_action()

func process_action(_delta: float) -> void:
    if !active || pb.throw.unhandledInput: return
    # account for objects not moved from their default origin
    var grabbedObjectOrigin = grabbedRef.get_node_or_null("GrabOrigin")
    var fromPos = grabbedRef.global_position if grabbedObjectOrigin == null else grabbedObjectOrigin.global_position
    var toPos = p.grabAnchor.global_position
    grabbedRef.linear_velocity = (toPos - fromPos) / _delta + p.velocity
    grabbedRef.angular_velocity *= 0.1

func stop_action() -> void:
    if !active: return
    pb.rotate.stop_action()
    reinit()
    p.grabArm.spring_length = p.TARGETING_DISTANCE
    p.grabArm.shape.radius = p.grabArmShapeRadius
