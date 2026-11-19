class_name ClimbBehavior
extends PlayerBehavior

const cannotTransitionFrom: Array[StringName] = [&"film_camera", &"drag", &"squeeze", &"vault"]
const mutuallyExclusiveWith: Array[StringName] = [&"flashlight", &"jump", &"rope"]

# garunteed to be in climbable group, a pseudo-interface with shared methods. see obsidian docs
var climbedRef: CollisionObject3D
# climbing uses path-following
var climbPath: Path3D
var climbCurve: Curve3D

func reinit() -> void:
    active = false
    climbedRef = null
    climbPath = null
    climbCurve = null

func can_act() -> bool:
    if (!active && p.adjacentRef != null && p.adjacentRef.is_in_group(&"climbable") && p.adjacentRef != pb.grab.grabbedRef && pb.none(cannotTransitionFrom)):
        if pb.crouch.active && !p.can_shape_change(): return false
        return p.adjacentRef.can_player_climb(p)
    return false

func start_action() -> void:
    if active: return
    if !p.adjacentRef.is_in_group(&"climbable"): return
    climbPath = p.adjacentRef.get_node_or_null("ClimbPath")
    if climbPath != null:
        climbedRef = p.adjacentRef
        climbCurve = climbPath.curve
        active = true
        pb.stop(mutuallyExclusiveWith)
        if pb.grab.active:
            climbedRef.add_collision_exception(pb.grab.grabbedRef)

func process_action(_delta: float) -> void:
    if !active: return
    # climbing behavior based velocity
    if climbCurve != null && climbPath != null:
        var closestOffset = climbCurve.get_closest_offset(climbPath.to_local(p.global_position))
        var offsetDelta: float = p.moveDir.y * Const.QUARTER_VOXEL
        var nextPoint: Vector3 = climbPath.to_global(climbCurve.sample_baked(closestOffset - offsetDelta))
        var toNextPoint: Vector3 = nextPoint - p.global_position
        var distToNextPoint: float = toNextPoint.length()
        if Utils.equalsf(0.0, distToNextPoint, 0.02):
            p.velocity = Vector3.ZERO
            return
        var climbDir: Vector3 = toNextPoint / distToNextPoint
        var scaledClimbSpeed: float = p.CLIMB_SPEED * abs(p.moveDir.y)
        var nextOffset: float = closestOffset + scaledClimbSpeed*_delta
        if nextOffset < 0.0 || nextOffset > climbCurve.get_baked_length():
            p.velocity = nextPoint - p.global_position
        else:
            p.velocity = climbDir * scaledClimbSpeed

func stop_action() -> void:
    if !active: return
    if pb.grab.active:
        climbedRef.del_collision_exception(pb.grab.grabbedRef)
    reinit()
