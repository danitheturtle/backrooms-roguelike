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
var ammo: float = 5.0
## track the toggle state of adjusting rope length while climbing or just swinging
var ropeExtensionLocked: bool = false

var ammoOnAttach: float
var lengthOnAttach: float
var currentMaxLength: float

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
    currentMaxLength = lengthOnAttach
    ropeExtensionLocked = false

func process_action(_delta: float) -> void:
    if !active: return
    var xzInputVelocity: Vector3 = Vector3.ZERO
    var climbInputVelocity: Vector3 = Vector3.ZERO
    p.velocity = Vector3(0,p.velocity.y,0)
    if ropeExtensionLocked || !ropeRef.lastPointBelowPivot || pb.jump.onFloorLastFrame:
        # for now this is mostly a copy of default movement
        # TODO put default movement in move_behavior and create new swinging movement here when player is dangling
        p.velocity += Vector3(p.basis.x * p.moveDir.x + p.basis.z * p.moveDir.y).limit_length() * p.CLIMB_SPEED
    elif !ropeExtensionLocked:
        #only move player up. gravity will carry them down
        var cameraZDotDown: float = p.camera.basis.z.dot(Vector3.DOWN)
        if cameraZDotDown > 0.0 && p.moveDir.y < 0.0 || cameraZDotDown <= 0.0 && p.moveDir.y > 0.0:
            p.velocity += -ropeRef.lastSegmentDir
        p.velocity += Vector3(p.basis.x * p.moveDir.x).limit_length()
    #p.velocity = Vector3(0,p.velocity.y,0) + xzInputVelocity + climbInputVelocity
    # limit speed against rope axis to desired climb speed
    var scaledClimbSpeed: float = p.CLIMB_SPEED * abs(p.moveDir.y)
    var speedInPivotDirection: float = p.velocity.dot(-ropeRef.lastSegmentDir)
    if (ropeRef.lastPointBelowPivot && speedInPivotDirection > scaledClimbSpeed):
        # subtract out all but climb speed in pivot dir
        p.velocity -= (speedInPivotDirection - scaledClimbSpeed) * -ropeRef.lastSegmentDir
    # if !ropeExtensionLocked, only change max length on player input. don't let gravity change it
    # if at end of currentMaxLength while ropeExtensionLocked, limit speedInRopeDir to climbing speed
    # rope store's last frame's data before this is called, which is used to calculate this frame's input velocity
    ropeRef.lastPoint = get_harness_position()
    ammo = ammoOnAttach - (ropeRef.length - lengthOnAttach)
    if ropeRef.length < currentMaxLength || !ropeExtensionLocked:
        currentMaxLength = ropeRef.length
    if ammo > 0.0 && !ropeExtensionLocked: return
    var speedInRopeDir: float = p.velocity.dot(ropeRef.lastSegmentDir)
    var nextLength: float =  ropeRef.length + speedInRopeDir
    # constrain movement to max length with pseudo-pendulum behavior
    if nextLength > currentMaxLength:
        var angleFromGravityVector = acos(ropeRef.lastSegmentDir.dot(Const.GRAVITY_VECTOR))
        var tangentDir = ropeRef.lastSegmentDir.rotated(Vector3.DOWN.cross(ropeRef.lastSegmentDir).normalized(), deg_to_rad(-90))
        var tangentAcceleration = tangentDir * Const.GRAVITY * sin(angleFromGravityVector) * _delta * p.ROPE_TANGENT_GRAVITY_MULTIPLIER
        # apply tangent velocity that acts as a centering force if the player is below the pivot
        if ropeRef.lastPointBelowPivot && !pb.jump.onFloorLastFrame:
            p.velocity += tangentAcceleration
        # Constrain velocity component that's in the direction of the rope to only carry player to the end and no further
        if ropeExtensionLocked:
            p.velocity -= ropeRef.lastSegmentDir * (nextLength - currentMaxLength)
        elif nextLength > currentMaxLength + ammo:
            p.velocity -= ropeRef.lastSegmentDir * (nextLength - (currentMaxLength + ammo))

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
    # TODO remove this once freefall doesn't happen on !ropeExtensionLocked
    if ropeExtensionLocked:
        currentMaxLength = ropeRef.length

## Harness is halfway up player collision shape
func get_harness_position() -> Vector3:
    return p.global_position + Vector3(0.0, p.playerShape.height / 2.0, 0.0)
