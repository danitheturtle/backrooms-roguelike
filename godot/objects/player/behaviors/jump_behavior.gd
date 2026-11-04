class_name JumpBehavior
extends PlayerBehavior

const cannotTransitionFrom: Array[StringName] = [&"vault", &"crouch", &"crawl", &"squeeze", &"film_camera", &"squeeze"]
const mutuallyExclusiveWith: Array[StringName] = [&"drag", &"climb"]

var unhandledInput: bool
var onFloorLastFrame: bool

func reinit() -> void:
    active = false
    unhandledInput = false
    onFloorLastFrame = true

func can_act() -> bool:
    return !active && pb.none(cannotTransitionFrom) && (onFloorLastFrame || pb.climb.active)

func start_action() -> void:
    if active || unhandledInput: return
    active = true
    pb.stop(mutuallyExclusiveWith)
    pb.target.stop_if_target_is_holdable()
    # TODO reduce if player just stopped climbing
    p.velocity += Vector3(0,p.JUMP_IMPULSE,0)

func process_action(_delta: float) -> void:
    # edge detect landing on floor to stop jump & vault
    var onFloorThisFrame = p.is_on_floor()
    if (onFloorThisFrame && !onFloorLastFrame):
        stop_action()
        if pb.sprint.can_act() && Input.is_action_pressed("sprint"):
            pb.sprint.start_action()
    onFloorLastFrame = onFloorThisFrame
    # jump starting is synced to physics instead of called directly
    if unhandledInput && !active && !pb.vault.active && (onFloorLastFrame || pb.climb.active):
        unhandledInput = false
        pb.vault.unhandledInput = false
        start_action()

func stop_action() -> void:
    if !active: return
    active = false
    unhandledInput = false
    onFloorLastFrame = true
    pb.vault.unhandledInput = false
