class_name RopeBehavior
extends PlayerBehavior

const cannotTransitionFrom: Array[StringName] = [&"climb", &"film_camera", &"drag", &"squeeze", &"vault"]
const mutuallyExclusiveWith: Array[StringName] = [&"flashlight", &"jump"]

var ropeRef: Rope
var ropePath: Path3D
var ropeCurve: Curve3D
var MAX_LENGTH: float = 3.0

func get_active() -> bool:
    return ropeRef != null

func reinit() -> void:
    active = false
    ropeRef = null

func can_act() -> bool:
    if (p.adjacentRef is Rope && p.adjacentRef != ropeRef && !active && pb.none(cannotTransitionFrom)):
        if pb.crouch.active && !p.can_shape_change(): return false
        return true
    return false

func start_action() -> void:
    if active: return
    ropeRef = p.adjacentRef
    ropePath = Utils.get_child_of_type(ropeRef, Path3D)
    ropeCurve = ropePath.curve
    if ropeCurve.point_count < 2:
        ropeCurve.add_point(ropeRef.to_local(p.global_position))
    active = true
    pb.stop(mutuallyExclusiveWith)

func process_action(_delta: float) -> void:
    if !active: return
    var playerPos = ropeRef.to_local(p.global_position)
    # update rope with last frame's player position
    ropeCurve.set_point_position(ropeCurve.point_count-1, playerPos)
    # constrain player velocity in direction of rope to the rope's length
    var playerToAnchor = playerPos - ropeCurve.get_point_position(0)
    var distanceToAnchor = playerToAnchor.length()
    if distanceToAnchor < MAX_LENGTH: return
    var ropeDir: Vector3 = playerToAnchor / distanceToAnchor
    var speedInRopeDir: float = p.velocity.dot(ropeDir)
    if distanceToAnchor + speedInRopeDir < MAX_LENGTH: return
    # this frame's velocity will take the player past the end of the rope. Constrain by cancelling it
    #p.velocity -= ropeDir * (distanceToAnchor + speedInRopeDir - MAX_LENGTH)
    var angleFromVertical = acos(ropeDir.dot(-Const.GRAVITY_VECTOR))
    var ropeTension = -Const.GRAVITY_VECTOR * Const.GRAVITY * cos(angleFromVertical)
    var tangentGravity = Const.GRAVITY_VECTOR * Const.GRAVITY * sin(angleFromVertical)
    # TODO ramp down desired movement velocity the further off-center the player is from the anchor

func stop_action() -> void:
    if !active: return
    reinit()
