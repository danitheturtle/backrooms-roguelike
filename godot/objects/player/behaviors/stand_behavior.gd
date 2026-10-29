class_name StandBehavior
extends PlayerBehavior

const mutuallyExclusiveWith: Array[StringName] = [&"crouch", &"squeeze", &"sprint"]

# Standing is the default player state. active on reinit
func reinit() -> void:
    active = true

func can_act() -> bool:
    return p.can_shape_change()

func start_action() -> void:
    active = true
    if (p.playerShape.height != p.standingHeight):
        p.playerShape.height = p.standingHeight
        p.playerCollider.position.y = p.standingHeight / 2.0
        p.camera.position.y = p.standingHeight - p.cameraTopOffset
    if (p.playerShape.radius != p.standingRadius):
        p.playerShape.radius = p.standingRadius
        p.flashlight.position.x = p.flashlightOffset.x
    pb.stop(mutuallyExclusiveWith)
    # find first rigidbody touching anchor, if it exists, and apply hover material
    for nextBody in p.grabAnchor.get_overlapping_bodies():
        if nextBody is RigidBody3D:
            p.on_grab_anchor_entered(nextBody)
            break

func try_action():
    await p.get_tree().process_frame
    await p.get_tree().process_frame
    if can_act(): start_action()
