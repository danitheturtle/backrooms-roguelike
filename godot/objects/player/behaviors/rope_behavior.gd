class_name RopeBehavior
extends PlayerBehavior

const RopeRes = preload("res://objects/rope/rope.tscn")
const MIN_ROPE_LENGTH: int = 5

const cannotTransitionFrom: Array[StringName] = [&"climb", &"crawl", &"film_camera", &"drag", &"squeeze", &"vault"]
const mutuallyExclusiveWith: Array[StringName] = [&"flashlight", &"jump"]

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
    var previousRopeLength: float = ropeRef.length
    # cut rope at the control point closest to the player. refund ammo of excess
    var closestPointIndex: int = ropeRef.get_nearest_control_point(get_harness_position())
    if closestPointIndex == 0:
        closestPointIndex = 1
    if ropeRef.path.curve.point_count-1 > closestPointIndex:
        for i: int in range(ropeRef.path.curve.point_count, closestPointIndex + 1):
            ropeRef.path.curve.remove_point(i)
    ropeRef.update_cached_length()
    move_end_to_player()
    lengthOnAttach = ropeRef.length
    ammo += previousRopeLength - lengthOnAttach
    ammoOnAttach = ammo
    currentMaxLength = lengthOnAttach

func process_action(_delta: float) -> void:
    if !active: return
    # needs alternate locomotion code while ropeExtensionLocked and !isOnFloor is true
    move_end_to_player()
    ammo = ammoOnAttach - (ropeRef.length - lengthOnAttach)
    if ropeRef.length < currentMaxLength || !ropeExtensionLocked:
        currentMaxLength = ropeRef.length
    #if ammo > 0.0 && !ropeExtensionLocked: return
    var ropeDir: Vector3 = ropeRef.lastSegment / ropeRef.lastSegmentLength
    var speedInRopeDir: float = p.velocity.dot(ropeDir)
    var nextLength: float =  ropeRef.length + speedInRopeDir
    # constrain movement to max length with pseudo-pendulum behavior
    if nextLength > currentMaxLength:
        var angleFromGravityVector = acos(ropeDir.dot(Const.GRAVITY_VECTOR))
        var tangentDir = ropeDir.rotated(Vector3.DOWN.cross(ropeDir).normalized(), deg_to_rad(-90))
        var tangentAcceleration = tangentDir * Const.GRAVITY * sin(angleFromGravityVector) * _delta * p.ROPE_TANGENT_GRAVITY_MULTIPLIER
        # apply tangent velocity that acts as a centering force if the player is below the anchor
        if ropeDir.dot(Vector3.DOWN) > 0.05 && !pb.jump.onFloorLastFrame:
            p.velocity += tangentAcceleration
        # Constrain velocity component that's in the direction of the rope to only carry player to the end and no further
        if ropeExtensionLocked:
            p.velocity -= ropeDir * (nextLength - currentMaxLength)
        elif nextLength > currentMaxLength + ammo:
            p.velocity -= ropeDir * (nextLength - (currentMaxLength + ammo))

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
    if ropeExtensionLocked:
        currentMaxLength = ropeRef.length

func move_end_to_player() -> void:
    ropeRef.path.curve.set_point_position(ropeRef.path.curve.point_count-1, ropeRef.to_local(get_harness_position()))
    ropeRef.update_last_segment_length()

## Harness is halfway up player collision shape
func get_harness_position() -> Vector3:
    return p.global_position + Vector3(0.0, p.playerShape.height / 2.0, 0.0)
