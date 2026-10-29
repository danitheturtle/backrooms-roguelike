class_name VaultBehavior
extends PlayerBehavior

const cannotTransitionFrom: Array[StringName] = [&"crouch", &"crawl", &"climb", &"squeeze", &"film_camera", &"grab", &"drag"]

var ledgePoint: Vector3
var justVaulted: bool

func reinit() -> void:
    active = false
    justVaulted = false
    ledgePoint = Vector3.ZERO

func can_act() -> bool:
    return !active && pb.none(cannotTransitionFrom)

func start_action():
    if active: return
    if ledgePoint == Vector3.ZERO: return
    var spaceState = p.get_world_3d().direct_space_state
    var standingQuery = PhysicsRayQueryParameters3D.create(
        ledgePoint,
        ledgePoint + Vector3(0.0, p.standingHeight + 0.025, 0.0),
        p.collision_mask
    )
    standingQuery.exclude = [self]
    var canStandAtDestination = spaceState.intersect_ray(standingQuery)
    var canCrouchAtDestination = false
    if !canStandAtDestination.is_empty():
        var crouchingQuery = PhysicsRayQueryParameters3D.create(
            ledgePoint,
            ledgePoint + Vector3(0.0, p.CROUCH_HEIGHT + 0.025, 0.0),
            p.collision_mask
        )
        crouchingQuery.exclude = [self]
        canCrouchAtDestination = spaceState.intersect_ray(crouchingQuery)
        if !canCrouchAtDestination.is_empty():
            return
        else:
            pb.crouch.tryStandAfterCrouching = false
            pb.crouch.start_action()
    active = true
    pb.sprint.stop_action()
    p.velocity = Vector3.ZERO
    var destination = ledgePoint - p.global_transform.basis.z * 0.1
    var start = p.global_position
    var mid = start.lerp(destination, 0.5) + Vector3(0.0, 0.5, 0.0)
    var tween = p.create_tween()
    tween.set_ease(Tween.EASE_IN_OUT)
    tween.set_trans(Tween.TRANS_SINE)
    tween.tween_method(bezier_move.bind(start, mid, destination + Vector3(0.0, 0.05, 0.0)), 0.0, 1.0, p.VAULT_DURATION)
    tween.tween_callback(stop_action)

func stop_action() -> void:
    if !active: return
    active = false
    pb.jump.stop_action()

func bezier_move(t: float, start: Vector3, mid: Vector3, end: Vector3):
    var pA = start.lerp(mid, t)
    var pB = mid.lerp(end, t)
    p.global_position = pA.lerp(pB, t)
