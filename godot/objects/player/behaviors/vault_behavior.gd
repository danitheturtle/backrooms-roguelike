class_name VaultBehavior
extends PlayerBehavior

const cannotTransitionFrom: Array[StringName] = [&"crouch", &"crawl", &"climb", &"squeeze", &"film_camera", &"grab", &"drag"]
const mutuallyExclusiveWith: Array[StringName] = [&"sprint"]

enum VaultMovementQueryResult { VALID, CROUCH, INVALID }

var vaultRayCast: RayCast3D
var ledgePoint: Vector3
var unhandledInput: bool

func player_ready() -> void:
    vaultRayCast = p.get_node("VaultSolverRayCast")

func reinit() -> void:
    active = false
    unhandledInput = false
    ledgePoint = Vector3.ZERO

func can_act() -> bool:
    return !active && pb.none(cannotTransitionFrom)

func start_action():
    if active || unhandledInput: return
    active = true
    pb.stop(mutuallyExclusiveWith)
    # vaulting takes over velocity
    p.velocity = Vector3.ZERO
    var destination = ledgePoint - p.global_transform.basis.z * 0.1
    var start = p.global_position
    var mid = start.lerp(destination, 0.5) + Vector3(0.0, 0.5, 0.0)
    var tween = p.create_tween()
    tween.set_ease(Tween.EASE_IN_OUT)
    tween.set_trans(Tween.TRANS_SINE)
    tween.tween_method(bezier_move.bind(start, mid, destination + Vector3(0.0, 0.05, 0.0)), 0.0, 1.0, p.VAULT_DURATION)
    tween.tween_callback(stop_action)

func process_action(_delta: float) -> void:
    if !active && unhandledInput:
        var testResult: VaultMovementQueryResult = vault_movement_query()
        if testResult == VaultMovementQueryResult.INVALID: return
        # only consume input if vault is going to happen
        unhandledInput = false
        pb.jump.unhandledInput = false
        if testResult == VaultMovementQueryResult.CROUCH:
            pb.crouch.tryStandAfterCrouching = false
            pb.crouch.start_action()
        start_action()

# vault movement doesn't use physics, so check that player can stand or crouch at final position
# TODO slightly buggy and doesn't check horizontal space
func vault_movement_query() -> VaultMovementQueryResult:
    vaultRayCast.force_raycast_update()
    if !vaultRayCast.is_colliding(): return VaultMovementQueryResult.INVALID
    if vaultRayCast.get_collider() is RigidBody3D: return VaultMovementQueryResult.INVALID
    ledgePoint = vaultRayCast.get_collision_point()
    var spaceState = p.get_world_3d().direct_space_state
    var standingQuery = PhysicsRayQueryParameters3D.create(
        ledgePoint,
        ledgePoint + Vector3(0.0, p.standingHeight + 0.025, 0.0),
        p.collision_mask
    )
    standingQuery.exclude = [player]
    var canStandAtDestination = spaceState.intersect_ray(standingQuery)
    var canCrouchAtDestination = false
    if canStandAtDestination.is_empty():
        return VaultMovementQueryResult.VALID
    else:
        var crouchingQuery = PhysicsRayQueryParameters3D.create(
            ledgePoint,
            ledgePoint + Vector3(0.0, p.CROUCH_HEIGHT + 0.025, 0.0),
            p.collision_mask
        )
        crouchingQuery.exclude = [player]
        canCrouchAtDestination = spaceState.intersect_ray(crouchingQuery)
        if !canCrouchAtDestination.is_empty():
            return VaultMovementQueryResult.INVALID
        else:
            return VaultMovementQueryResult.CROUCH

func bezier_move(t: float, start: Vector3, mid: Vector3, end: Vector3):
    var pA = start.lerp(mid, t)
    var pB = mid.lerp(end, t)
    p.global_position = pA.lerp(pB, t)
