class_name CrouchBehavior
extends PlayerBehavior

const mutuallyExclusiveWith: Array[StringName] = [&"stand", &"squeeze", &"crawl", &"drag", &"film_camera"]

var previousBehavior: StringName
var tryStandAfterCrouching: bool
var slideVelocity: float

func reinit() -> void:
    active = false
    previousBehavior = &""
    tryStandAfterCrouching = false
    slideVelocity = 0.0

func can_act() -> bool:
    if active: return false
    return p.can_shape_change()

func start_action() -> void:
    if active: return
    active = true
    pb.stop(mutuallyExclusiveWith)
    set_positions()
    if (pb.sprint.active):
        # apply slide impulse in direction of sprint
        slideVelocity = p.SLIDE_IMPULSE
        pb.sprint.stop_action()
    p.try_clear_hover_state()
    if tryStandAfterCrouching:
        await p.get_tree().process_frame
        if pb.stand.can_act():
            pb.stand.start_action()

func process_action(_delta: float) -> void:
    if !active: return
    if slideVelocity > 0.0:
        slideVelocity -= p.SLIDE_DECELERATION * _delta
    elif slideVelocity != 0.0:
        slideVelocity = 0.0

func set_positions() -> void:
    p.set_default_positions()
    # move camera down and set player height to crouched
    p.playerShape.height = p.CROUCH_HEIGHT
    p.playerCollider.position.y = p.CROUCH_HEIGHT / 2.0
    p.camera.position.y = p.CROUCH_HEIGHT - p.cameraTopOffset
