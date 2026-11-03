class_name GrabBehavior
extends PlayerBehavior

const cannotTransitionFrom: Array[StringName] = [&"drag", &"jump", &"vault", &"crouch", &"crawl", &"squeeze", &"sprint", &"climb", &"film_camera"]
const mutuallyExclusiveWith: Array[StringName] = [&"target", &"flashlight"]

var grabArm: SpringArm3D
var grabAnchor: Marker3D
var grabbedRef: Holdable
var justGrabbed: bool
var justDroppedRef: Holdable
var grabArmShapeRadius: float

func get_active() -> bool: return grabbedRef != null

func set_active(_nextVal: bool) -> void: pass

func player_ready() -> void:
    grabArm = p.get_node("Camera/GrabArm")
    grabAnchor = p.get_node("Camera/GrabArm/GrabAnchor")
    grabArmShapeRadius = grabArm.shape.radius

func reinit() -> void:
    justGrabbed = false
    if active:
        grabbedRef.on_drop()
        justDroppedRef = grabbedRef
        grabbedRef = null

func can_act() -> bool:
    if (!active && pb.none(cannotTransitionFrom) && pb.jump.onFloorLastFrame):
        return not (pb.target.ref is Holdable && pb.target.ref.mass > p.MAX_GRAB_MASS)
    else:
        return false

func start_action() -> void:
    if active: return
    pb.target.ref.on_hold(player)
    grabArm.spring_length = pb.target.ref.heldDistance
    grabArm.shape.radius = pb.target.ref.heldCollisionRadius
    # causes visual bug as spring arm rapidly shifts if we don't wait a frame
    await p.get_tree().process_frame
    grabbedRef = pb.target.ref
    justGrabbed = true
    pb.stop(mutuallyExclusiveWith)
    # always rotate on pickup
    pb.rotate.start_action()

func process_action(_delta: float) -> void:
    if justDroppedRef != null:
        no_collision_till_player_exits()
    if !active || pb.throw.unhandledInput: return
    # account for objects not grabbed from their default origin
    var grabbedObjectOrigin = grabbedRef.get_node_or_null("GrabOrigin")
    var fromPos = grabbedRef.global_position if grabbedObjectOrigin == null else grabbedObjectOrigin.global_position
    var toPos = grabAnchor.global_position
    # if player is too far, drop object
    var nextTravelDistanceSq: float = (toPos - fromPos).length_squared()
    if nextTravelDistanceSq > grabbedRef.heldDistance * grabbedRef.heldDistance * 2:
        stop_action()
    else:
        grabbedRef.linear_velocity = (toPos - fromPos) / _delta + p.velocity
        # damp angular movement
        grabbedRef.angular_velocity *= 0.1

func stop_action() -> void:
    if !active: return
    pb.rotate.stop_action()
    if pb.climb.active:
        pb.climb.climbedRef.del_collision_exception(grabbedRef)
    reinit()
    grabArm.spring_length = p.TARGETING_DISTANCE
    grabArm.shape.radius = grabArmShapeRadius

func increase_held_distance() -> void:
    grabArm.spring_length = min(grabbedRef.maxHeldDistance, grabArm.spring_length + grabbedRef.heldDistanceStep)

func decrease_held_distance() -> void:
    grabArm.spring_length = max(grabbedRef.heldCollisionRadius * 1.5, grabArm.spring_length - grabbedRef.heldDistanceStep)

func no_collision_till_player_exits() -> void:
    if p.nearbyBodies.has(justDroppedRef):
        justDroppedRef.add_collision_exception(player)
    else:
        justDroppedRef.del_collision_exception(player)
        justDroppedRef = null
