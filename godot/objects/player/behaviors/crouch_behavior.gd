class_name CrouchBehavior
extends PlayerBehavior

const mutuallyExclusiveWith: Array[StringName] = [&"grab", &"drag", &"film_camera"]

var tryStandAfterCrouching: bool

func reinit() -> void:
    active = false
    tryStandAfterCrouching = false

func can_act() -> bool:
    if (!pb.crawl.active):
        return !pb.squeeze.active
    else:
        return p.can_shape_change()

func start_action() -> void:
    if active: return
    active = true
    pb.stop(mutuallyExclusiveWith)
    # move camera down and set player height to crouched
    p.playerShape.height = p.CROUCH_HEIGHT
    p.playerShape.radius = p.standingRadius
    p.playerCollider.position.y = p.CROUCH_HEIGHT / 2.0
    p.playerCollider.rotation.z = 0.0
    p.roomForStateChangeShape.height = p.standingHeight
    p.roomForStateChangeShape.radius = p.standingRadius
    p.roomForStateChangeCollider.position.y = p.standingHeight / 2.0
    p.camera.position.y = p.CROUCH_HEIGHT - p.cameraTopOffset
    p.flashlight.position.y = p.flashlightOffset.y
    if (pb.sprint.active):
        # apply slide impulse in direction of sprint
        p.slideVelocity = p.SLIDE_IMPULSE
        pb.sprint.stop_action()
    pb.crawl.stop_action()
    p.try_clear_hover_state()
    if tryStandAfterCrouching: pb.stand.call_deferred("try_action")
