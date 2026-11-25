class_name MoveBehavior
extends PlayerBehavior

const cannotTransitionFrom: Array[StringName] = [&"rope", &"climb", &"vault"]

func can_act() -> bool:
    return pb.none(cannotTransitionFrom)

func process_action(_delta: float) -> void:
    # basic movement, skip for behaviors that have their own locomotion6
    if can_act():
        var movementSpeed: float = get_current_move_speed() + pb.crouch.slideVelocity
        # dampen side-to-side movement when crawling
        var moveDirXComponent  = p.moveDir.x 
        if pb.crawl.active:
            moveDirXComponent *= p.CRAWL_STRAFE_DAMPING
        #multiply basis vectors by input direction. preserve vertical velocity
        p.velocity = Vector3(0,p.velocity.y,0) + Vector3(p.basis.x * moveDirXComponent + p.basis.z * p.moveDir.y).limit_length() * movementSpeed

func get_current_move_speed() -> float:
    if pb.sprint.active:
        if pb.grab.active:
            return p.SPRINT_GRAB_SPEED
        else:
            return p.SPRINT_SPEED
    elif pb.some([&"crouch", &"squeeze", &"drag", &"film_camera"]):
        return p.SLOWED_SPEED
    elif pb.grab.active:
        return p.GRAB_SPEED
    elif pb.crawl.active:
        return p.EXTRA_SLOW_SPEED
    else:
        return p.PLAYER_SPEED
