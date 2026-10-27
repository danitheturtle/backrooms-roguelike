class_name StandBehavior
extends PlayerBehavior

# TODO other behaviors need to set active to false

# Standing is the default player state. active on reinit
func reinit() -> void:
    super.reinit()
    active = true

func can_act() -> bool:
    return p.can_shape_change()
func start_action() -> void:
    if (p.playerShape.height != p.standingHeight):
        p.playerShape.height = p.standingHeight
        p.playerCollider.position.y = p.standingHeight / 2.0
        p.camera.position.y = p.standingHeight - p.cameraTopOffset
        p.b.crouch.active = false
    if (p.playerShape.radius != p.standingRadius):
        p.playerShape.radius = p.standingRadius
        p.flashlight.position.x = p.flashlightOffset.x
        p.b.squeeze.active = false
    p.b.sprint.active = false
    # find first rigidbody touching anchor, if it exists, and apply hover material
    for nextBody in p.grabAnchor.get_overlapping_bodies():
        if nextBody is RigidBody3D:
            p.on_grab_anchor_entered(nextBody)
            break
    active = true
func process_action(_delta: float) -> void: pass
func stop_action() -> void: pass

func try_action():
    await p.get_tree().process_frame
    await p.get_tree().process_frame
    if can_act():
        start_action()
