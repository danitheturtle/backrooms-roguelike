class_name StandBehavior
extends PlayerBehavior

const mutuallyExclusiveWith: Array[StringName] = [&"crawl", &"crouch", &"squeeze"]

# Standing is the default player state
func reinit() -> void:
    active = true

func can_act() -> bool:
    return !active && p.can_shape_change()

func start_action() -> void:
    if active: return
    active = true
    pb.stop(mutuallyExclusiveWith)
    p.set_default_positions()
    # find first rigidbody touching anchor, if it exists, and apply hover material
    for nextBody in p.grabAnchor.get_overlapping_bodies():
        if nextBody is RigidBody3D:
            p.on_grab_anchor_entered(nextBody)
            break
