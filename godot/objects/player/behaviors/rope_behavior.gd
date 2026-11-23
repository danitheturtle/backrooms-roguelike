class_name RopeBehavior
extends PlayerBehavior

const RopeRes = preload("res://objects/rope/rope.tscn")
const MAX_TARGET_DIST_FROM_PLAYER: float = Const.HALF_VOXEL

const cannotTransitionFrom: Array[StringName] = [&"climb", &"crawl", &"film_camera", &"drag", &"squeeze", &"vault"]
const mutuallyExclusiveWith: Array[StringName] = [&"flashlight", &"jump", &"crouch"]

var ropeRef: Rope
## tracks whether this is the active action on the action wheel
var ropeActionActive: bool = true
## player's carried rope ammo
var ammo: float = 20.0
## track the toggle state of adjusting rope length while climbing or just swinging
var ropeExtensionLocked: bool = false

var ammoOnAttach: float
var lengthOnAttach: float
var targetLength: float
var maxLength: float
var minLength: float

func get_active() -> bool:
    return ropeRef != null

func reinit() -> void:
    ropeRef = null
    ropeExtensionLocked = false
    ropeActionActive = true # TODO action wheel shit
    minLength = 0.0
    maxLength = 1.0

func can_act() -> bool:
    if (p.adjacentRef is Rope && p.adjacentRef != ropeRef && !active && pb.none(cannotTransitionFrom)):
        if pb.crouch.active && !p.can_shape_change(): return false
        return true
    return false

func start_action() -> void:
    if active: return
    pb.stop(mutuallyExclusiveWith)
    ropeRef = p.adjacentRef
    var harnessPosition: Vector3 = get_harness_position()
    var closestPointIndex: int = ropeRef.get_nearest_control_point(harnessPosition)
    # cut rope at the control point closest to the player. refund ammo excess
    if ropeRef.path.curve.point_count-1 > closestPointIndex:
        for i: int in range(ropeRef.path.curve.point_count-1, closestPointIndex + 1, -1):
            ropeRef.path.curve.remove_point(i)
    ropeRef.remove_excess_shapes()
    ropeRef.lastPoint = harnessPosition
    ropeRef.update_cached_length()
    lengthOnAttach = ropeRef.length
    ammo += ropeRef.storedAmmo - lengthOnAttach
    ammoOnAttach = ammo
    targetLength = lengthOnAttach
    maxLength = lengthOnAttach + ammoOnAttach
    ropeExtensionLocked = false

func process_action(_delta: float) -> void:
    if !active: return
    if pb.jump.onFloorLastFrame:
        ropeExtensionLocked = false
    ropeRef.lastPoint = get_harness_position()
    var castResult: Dictionary = ropeRef.shapecast_segment(ropeRef.pivotIndex)
    if !castResult.is_empty():
        ropeRef.wrap_around_geometry(castResult, ropeRef.lastIndex)
    else:
        ropeRef.try_unwrap_point(ropeRef.pivotIndex, true)
    ammo = ammoOnAttach - (ropeRef.length - lengthOnAttach)
    var nextPlayerVelocity: Vector3 = Vector3(0.0,p.velocity.y,0.0)
    
    var velocityFromInput: Vector3 = get_velocity_from_input()
    nextPlayerVelocity += velocityFromInput
    
    var tangentAcceleration: Vector3 = get_tangent_acceleration(_delta)
    nextPlayerVelocity += tangentAcceleration
    
    var scaledClimbSpeed: float = 0.0
    if !ropeExtensionLocked:
        scaledClimbSpeed = p.CLIMB_SPEED * velocityFromInput.normalized().dot(ropeRef.pivotArmDir)
    
    # update target length based on input speed, clamp to current min/max
    targetLength = clamp(
        targetLength + scaledClimbSpeed * _delta, 
        max(minLength, ropeRef.length - MAX_TARGET_DIST_FROM_PLAYER),
        min(ropeRef.length + MAX_TARGET_DIST_FROM_PLAYER, maxLength)
    )
    
    # keep player at target length of rope
    var speedOnRopeAxis: float = nextPlayerVelocity.dot(ropeRef.pivotArmDir)
    var nextFrameLength = ropeRef.length + speedOnRopeAxis * _delta
    var correctingVelocity: Vector3 = Vector3.ZERO
    if ropeRef.lastPointBelowPivot && !pb.jump.onFloorLastFrame || nextFrameLength >= maxLength:
        correctingVelocity = -ropeRef.pivotArmDir * (nextFrameLength - targetLength) / _delta
    nextPlayerVelocity += correctingVelocity
    
    # directly set final player velocity for this behavior
    p.velocity = nextPlayerVelocity

func stop_action() -> void:
    if !active: return
    reinit()

func can_place_rope() -> bool:
    return ropeActionActive && !active && pb.target.active && pb.target.ref.is_in_group(&"anchorable")

func place_new_rope(_anchoredToRef: PhysicsBody3D, _offset: Vector3) -> Rope:
    var newRope: Rope = RopeRes.instantiate()
    newRope.transform.origin = _offset
    newRope.anchoredTo = _anchoredToRef
    _anchoredToRef.add_child(newRope)
    return newRope

func toggle_extension_mode() -> void:
    if pb.jump.onFloorLastFrame: return
    ropeExtensionLocked = !ropeExtensionLocked

## Harness is halfway up player collision shape
func get_harness_position() -> Vector3:
    return p.global_position + Vector3(0.0, p.playerShape.height / 2.0, 0.0)

## get rope climb velocity from player input
func get_velocity_from_input() -> Vector3:
    var velocityFromInput: Vector3 = Vector3.ZERO
    if ropeExtensionLocked && !pb.jump.onFloorLastFrame || !ropeRef.lastPointBelowPivot:
        # for now this is mostly a copy of default movement, but it should be swinging
        # TODO put default movement in move_behavior and create new swinging movement here when player is dangling
        velocityFromInput = Vector3(p.basis.x * p.moveDir.x + p.basis.z * p.moveDir.y).limit_length() * p.CLIMB_SPEED
    else:
        var yMoveComponent: Vector3 = Vector3.ZERO
        var xMoveComponent: Vector3 = Vector3(p.basis.x * p.moveDir.x).limit_length() * p.CLIMB_SPEED
        var ropeDirMoveComponent: Vector3 = Vector3.ZERO
        if !Utils.equalsf(p.moveDir.y, 0.0):
            # split y movement between rope axis and camera direction if player is on floor
            ropeDirMoveComponent = ropeRef.pivotArmDir * p.moveDir.y * p.CLIMB_SPEED
            if pb.jump.onFloorLastFrame:
                var zDotRopeDir = p.basis.z.dot(ropeRef.pivotArmDir)
                ropeDirMoveComponent *= zDotRopeDir
                yMoveComponent = Vector3(p.basis.z * p.moveDir.y) * p.CLIMB_SPEED * sin(acos(zDotRopeDir))
        velocityFromInput += xMoveComponent + yMoveComponent + ropeDirMoveComponent
    return velocityFromInput

## Tangent acceleration that acts as a centering force while the player is below the pivot
func get_tangent_acceleration(_delta: float) -> Vector3:
    var tangentAcceleration: Vector3 = Vector3.ZERO
    if ropeRef.lastPointBelowPivot && !pb.jump.onFloorLastFrame:
        var angleFromGravityVector = acos(ropeRef.pivotArmDir.dot(Const.GRAVITY_VECTOR))
        var tangentDir = ropeRef.pivotArmDir.rotated(Const.GRAVITY_VECTOR.cross(ropeRef.pivotArmDir).normalized(), deg_to_rad(-90))
        tangentAcceleration = tangentDir * Const.GRAVITY * sin(angleFromGravityVector) * _delta * p.ROPE_TANGENT_GRAVITY_MULTIPLIER
    return tangentAcceleration
