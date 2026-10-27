class_name ClimbBehavior
extends PlayerBehavior

# climbing uses path-following
var climbPath: Path3D
var climbCurve: Curve3D

func reinit() -> void:
    super.reinit()
    climbPath = null
    climbCurve = null

func can_act() -> bool:
    if (p.adjacentRef != null && p.adjacentRef != p.heldObjectRef && !active && !p.photographing && !p.dragging && !p.b.squeeze.active && !p.b.vault.active):
        if p.b.crouch.active: return p.can_shape_change()
        return true
    return false
func start_action() -> void:
    climbPath = p.adjacentRef.get_node_or_null("ClimbPath")
    if climbPath != null:
        climbCurve = climbPath.curve
        active = true
func process_action(_delta: float) -> void:
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
    active = false
    climbPath = null
    climbCurve = null
