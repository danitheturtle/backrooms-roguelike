class_name CrouchBehavior
extends PlayerBehavior

var tryStandAfterCrouching: bool

func reinit() -> void:
    super.reinit()
    tryStandAfterCrouching = false

func can_act() -> bool:
    if (!player.crawling):
        return !player.squeezing
    else:
        return player.can_shape_change()
func start_action() -> void:
    if (player.grabbing || player.dragging || player.photographing):
        # stop photographing
        player.handle_drop()
    # move camera down and set player height to crouched
    player.playerShape.height = player.CROUCH_HEIGHT
    player.playerShape.radius = player.standingRadius
    player.playerCollider.position.y = player.CROUCH_HEIGHT / 2.0
    player.playerCollider.rotation.z = 0.0
    player.roomForStateChangeShape.height = player.standingHeight
    player.roomForStateChangeShape.radius = player.standingRadius
    player.roomForStateChangeCollider.position.y = player.standingHeight / 2.0
    player.camera.position.y = player.CROUCH_HEIGHT - player.cameraTopOffset
    player.flashlight.position.y = player.flashlightOffset.y
    if (player.sprinting):
        # apply slide impulse in direction of sprint
        player.slideVelocity = player.SLIDE_IMPULSE
        player.sprinting = false
    player.crawling = false
    active = true
    player.try_clear_hover_state()
    if tryStandAfterCrouching: player.call_deferred("try_stand")
func process_action(_delta: float) -> void: pass
func end_action() -> void: pass
