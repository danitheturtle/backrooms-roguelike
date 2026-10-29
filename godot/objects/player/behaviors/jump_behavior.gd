class_name JumpBehavior
extends PlayerBehavior

const cannotTransitionFrom: Array[StringName] = [&"vault", &"crouch", &"crawl", &"squeeze", &"film_camera", &"squeeze", &"sprint", &"climb", &"film_camera"]
const mutuallyExclusiveWith: Array[StringName] = [&"drag", &"climb"]
var justJumped: bool = false

func reinit() -> void:
    active = false
    justJumped = false

func can_act() -> bool:
    return !active && pb.none(cannotTransitionFrom) && (p.onFloorLastFrame || pb.climb.active)

func start_action() -> void:
    if active: return
    active = true
    p.try_clear_hover_state()
    p.velocity += Vector3(0,p.JUMP_IMPULSE,0)
    pb.stop(mutuallyExclusiveWith)
func stop_action() -> void:
    if !active: return
    active = false
    pb.vault.stop_action()
