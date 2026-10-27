class_name CrouchBehavior
extends PlayerBehavior

var tryStandAfterCrouching: bool

func reinit() -> void:
    super.reinit()
    tryStandAfterCrouching = false

func can_act() -> bool:
    if (!p.b.crawl.active):
        return !p.b.squeeze.active
    else:
        return p.can_shape_change()
func start_action() -> void:
    if (p.grabbing || p.dragging || p.photographing):
        # stop photographing
        p.handle_drop()
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
    if (p.b.sprint.active):
        # apply slide impulse in direction of sprint
        p.slideVelocity = p.SLIDE_IMPULSE
        p.b.sprint.active = false
    p.b.crawl.active = false
    active = true
    p.try_clear_hover_state()
    if tryStandAfterCrouching: p.call_deferred("try_stand")
func process_action(_delta: float) -> void: pass
func end_action() -> void: pass
