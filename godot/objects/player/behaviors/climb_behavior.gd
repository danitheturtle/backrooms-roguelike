class_name ClimbBehavior
extends PlayerBehavior

const cannotTransitionFrom: Array[StringName] = [&"film_camera", &"drag", &"squeeze", &"vault"]
const mutuallyExclusiveWith: Array[StringName] = [&"flashlight"]

# garunteed to be in climbable group, a pseudo-interface with shared methods
var climbedRef: Node3D
# climbing uses path-following
var climbPath: Path3D
var climbCurve: Curve3D

func reinit() -> void:
    active = false
    climbedRef = null
    climbPath = null
    climbCurve = null

func can_act() -> bool:
    if (p.adjacentRef != null && p.adjacentRef != pb.grab.grabbedRef && !active && pb.none(cannotTransitionFrom)):
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
        var playerPosInLocalCurveSpace = climbPath.to_local(p.global_position)
        var closestOffset = climbCurve.get_closest_offset(playerPosInLocalCurveSpace)
        # adjust offset based on direction clamped to up/down
        closestOffset -= p.moveDir.y * p.CLIMB_SPEED
        # I don't know why the z axis needs reversed and at this point I'm too afraid to ask
        var nearestPoint = climbPath.global_position + climbCurve.sample_baked(closestOffset) * Basis(climbPath.global_basis.x, climbPath.global_basis.y, -climbPath.global_basis.z)
        # get required velocity to keep player at new location
        p.velocity = nearestPoint - p.global_position

func stop_action() -> void:
    if !active: return
    if pb.grab.active:
        climbedRef.del_collision_exception(pb.grab.grabbedRef)
    reinit()
