class_name RopeBehavior
extends PlayerBehavior

const RopeRes = preload("res://objects/rope/rope.tscn")
const MIN_ROPE_LENGTH: int = 5

const cannotTransitionFrom: Array[StringName] = [&"climb", &"film_camera", &"drag", &"squeeze", &"vault"]
const mutuallyExclusiveWith: Array[StringName] = [&"flashlight", &"jump"]

var ropeRef: Rope
var ropePlacementActive: bool = true
## player's carried rope ammo. unit is length in voxels
var ammo: int = 10

func get_active() -> bool:
    return ropeRef != null

func reinit() -> void:
    active = false
    ropeRef = null
    ropePlacementActive = true

func can_act() -> bool:
    if (p.adjacentRef is Rope && p.adjacentRef != ropeRef && !active && pb.none(cannotTransitionFrom)):
        if pb.crouch.active && !p.can_shape_change(): return false
        return true
    return false

func start_action() -> void:
    if active: return
    ropeRef = p.adjacentRef
    ropeRef.playerAmmoAtCreation = ammo
    active = true
    pb.stop(mutuallyExclusiveWith)

func process_action(_delta: float) -> void:
    if !active: return
    var pointCount = ropeRef.path.curve.point_count
    # last point = player pos, second to last point = pivot. stored in curve-local space
    ropeRef.path.curve.set_point_position(pointCount-1, ropeRef.to_local(p.global_position))
    var pivotPos: Vector3 = ropeRef.to_global(ropeRef.path.curve.get_point_position(pointCount-2))
    if ropeRef.lengthVoxels < ammo: return
    var playerToAnchor = p.global_position - pivotPos
    var distanceToAnchor = playerToAnchor.length()
    # return if slack rope
    var ropeDir: Vector3 = playerToAnchor / distanceToAnchor
    var speedInRopeDir: float = p.velocity.dot(ropeDir)
    # if this frame's velocity won't take player past rope end, do nothing
    if ropeRef.length + speedInRopeDir < Const.VOXEL * ammo: return
    # calculate pseudo-pendulum behavior
    var angleFromVertical = acos(ropeDir.dot(Const.GRAVITY_VECTOR))
    var tangentDir = ropeDir.rotated(Vector3.DOWN.cross(ropeDir).normalized(), deg_to_rad(-90))
    var tangentGravity = tangentDir * Const.GRAVITY * sin(angleFromVertical) * _delta * p.ROPE_TANGENT_GRAVITY_MULTIPLIER
    # Constrain velocity component that's in the direction of the rope to only carry player to the end and no further
    p.velocity -= ropeDir * (ropeRef.length + speedInRopeDir - Const.VOXEL * ammo)
    # apply tangent velocity that acts as a centering force if the player is below the anchor
    if ropeDir.dot(Vector3.DOWN) > 0.05: p.velocity += tangentGravity

func stop_action() -> void:
    if !active: return
    reinit()

func can_place_rope() -> bool:
    return ropePlacementActive && pb.target.active && pb.target.ref.is_in_group(&"anchorable")

func place_new_rope(_anchorRef: PhysicsBody3D, _offset: Vector3) -> Rope:
    var newRope: Rope = RopeRes.instantiate()
    newRope.transform.origin = _offset
    _anchorRef.add_child(newRope)
    return newRope
