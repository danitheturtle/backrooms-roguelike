class_name RopeBehavior
extends PlayerBehavior

const RopeRes = preload("res://objects/rope/rope.tscn")
const MIN_ROPE_LENGTH: int = 5

const cannotTransitionFrom: Array[StringName] = [&"climb", &"crawl", &"film_camera", &"drag", &"squeeze", &"vault"]
const mutuallyExclusiveWith: Array[StringName] = [&"flashlight", &"jump", &"crouch"]

var ropeRef: Rope
## tracks whether this is the active action on the action wheel
var ropeActionActive: bool = true
## player's carried rope ammo
var ammo: float = 15.0
## track the toggle state of adjusting rope length while climbing or just swinging
var ropeExtensionLocked: bool = false

var ammoOnAttach: float
var lengthOnAttach: float
var targetLength: float

func get_active() -> bool:
    return ropeRef != null

func reinit() -> void:
    ropeRef = null
    ropeActionActive = true # TODO action wheel shit

func can_act() -> bool:
    if (p.adjacentRef is Rope && p.adjacentRef != ropeRef && !active && pb.none(cannotTransitionFrom)):
        if pb.crouch.active && !p.can_shape_change(): return false
        return true
    return false

func start_action() -> void:
    if active: return
    pb.stop(mutuallyExclusiveWith)
    ropeRef = p.adjacentRef
    var ropeLengthBeforePickup: float = ropeRef.length
    var closestPointIndex: int = ropeRef.get_nearest_control_point(get_harness_position())
    # never get the first point since its the anchor
    if closestPointIndex == 0:
        closestPointIndex = 1
    # cut rope at the control point closest to the player. refund ammo excess
    if ropeRef.path.curve.point_count-1 > closestPointIndex:
        for i: int in range(ropeRef.path.curve.point_count, closestPointIndex + 1):
            ropeRef.path.curve.remove_point(i)
    ropeRef.lastPoint = get_harness_position()
    ropeRef.update_cached_length()
    lengthOnAttach = ropeRef.length
    ammo += ropeLengthBeforePickup - lengthOnAttach
    ammoOnAttach = ammo
    targetLength = lengthOnAttach
    ropeExtensionLocked = false

func process_action(_delta: float) -> void:
    if !active: return
    ropeRef.lastPoint = get_harness_position()
    ammo = ammoOnAttach - (ropeRef.length - lengthOnAttach)
    p.velocity = Vector3(0.0,p.velocity.y,0.0)
    
    # get velocity from player input
    var velocityFromInput: Vector3 = Vector3.ZERO
    if ropeExtensionLocked || !ropeRef.lastPointBelowPivot:
        # for now this is mostly a copy of default movement
        # TODO put default movement in move_behavior and create new swinging movement here when player is dangling
        velocityFromInput = Vector3(p.basis.x * p.moveDir.x + p.basis.z * p.moveDir.y).limit_length() * p.CLIMB_SPEED
    elif !ropeExtensionLocked:
        # because y velocity is preserved frame to frame, this accelerates very quickly. clamp velocity along rope dir
        if p.moveDir.y < 0.0:
            velocityFromInput += -ropeRef.lastSegmentDir
        elif p.moveDir.y > 0.0:
            velocityFromInput += ropeRef.lastSegmentDir
        velocityFromInput += Vector3(p.basis.x * p.moveDir.x).limit_length() * p.CLIMB_SPEED
    p.velocity += velocityFromInput
    
    # apply tangent velocity that acts as a centering force if the player is below the pivot
    var tangentAcceleration: Vector3 = Vector3.ZERO
    if ropeRef.lastPointBelowPivot && !pb.jump.onFloorLastFrame:
        var angleFromGravityVector = acos(ropeRef.lastSegmentDir.dot(Const.GRAVITY_VECTOR))
        var tangentDir = ropeRef.lastSegmentDir.rotated(Const.GRAVITY_VECTOR.cross(ropeRef.lastSegmentDir).normalized(), deg_to_rad(-90))
        tangentAcceleration = tangentDir * Const.GRAVITY * sin(angleFromGravityVector) * _delta * p.ROPE_TANGENT_GRAVITY_MULTIPLIER
    p.velocity += tangentAcceleration
    
    # rope axis and speed for clamping
    var scaledClimbSpeed: float = 0.0 if ropeExtensionLocked else abs(p.CLIMB_SPEED * p.moveDir.y)
    var speedOnRopeAxis: float = p.velocity.dot(ropeRef.lastSegmentDir)
    var speedAgainstRopeAxis: float = -speedOnRopeAxis
    
    # always shorten target length if actual rope length is shorter. prevents float drift
    if ropeRef.length < targetLength:
        targetLength = ropeRef.length
    # increase rope length by climbing speed if player is moving against rope axis.
    if ammo > 0.0 && !ropeExtensionLocked && speedOnRopeAxis > 0.0:
        # velocity doesn't use _delta so don't use here
        targetLength += scaledClimbSpeed
    
    # clamp upwards velocity
    var upwardsClamp: Vector3 = Vector3.ZERO
    if ropeRef.lastPointBelowPivot && speedAgainstRopeAxis > scaledClimbSpeed:
        upwardsClamp = (speedAgainstRopeAxis - scaledClimbSpeed) * ropeRef.lastSegmentDir
    p.velocity += upwardsClamp
    
    # if velocity would take player past the rope length, keep them at the end
    var downwardsClamp: Vector3 = Vector3.ZERO
    var nextLength: float = ropeRef.length + speedOnRopeAxis
    if nextLength > targetLength:
        downwardsClamp = -ropeRef.lastSegmentDir * (nextLength - targetLength)
    p.velocity += downwardsClamp
    #Utils.draw_vector("targetLength", ropeRef.pivotPoint, ropeRef.lastSegmentDir * targetLength, Color.ORANGE, 0.0001)
    #Utils.draw_vector("inputVelocity", get_harness_position(), velocityFromInput, Color.BLUE, 0.001)
    #Utils.draw_vector("tangentAcceleration", get_harness_position(), tangentAcceleration, Color.YELLOW, 0.001)
    #Utils.draw_vector("upwardsClamp", get_harness_position(), upwardsClamp, Color.RED, 0.0015)
    #Utils.draw_vector("downwardsClamp", get_harness_position(), downwardsClamp, Color.GREEN, 0.0015)
    #Utils.draw_vector("playerVelocity", get_harness_position(), p.velocity, Color.HOT_PINK, 0.0005)

func stop_action() -> void:
    if !active: return
    reinit()

func can_place_rope() -> bool:
    return ropeActionActive && !active && pb.target.active && pb.target.ref.is_in_group(&"anchorable")

func place_new_rope(_anchorRef: PhysicsBody3D, _offset: Vector3) -> Rope:
    var newRope: Rope = RopeRes.instantiate()
    newRope.transform.origin = _offset
    _anchorRef.add_child(newRope)
    return newRope

func toggle_extension_mode() -> void:
    ropeExtensionLocked = !ropeExtensionLocked

## Harness is halfway up player collision shape
func get_harness_position() -> Vector3:
    return p.global_position + Vector3(0.0, p.playerShape.height / 2.0, 0.0)
