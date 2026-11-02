class_name MoveBehavior
extends PlayerBehavior

const cannotTransitionFrom: Array[StringName] = [&"climb", &"vault"]

func can_act() -> bool:
    return pb.none(cannotTransitionFrom)

func process_action(_delta: float) -> void:
    # apply gravity and movement, skipping for behaviors that directly manipulate position
    if can_act():
        var movementSpeed: float = get_current_move_speed() + pb.crouch.slideVelocity
        # dampen side-to-side movement when crawling
        var moveDirXComponent  = p.moveDir.x 
        if pb.crawl.active:
            moveDirXComponent *= p.CRAWL_STRAFE_DAMPING
        #multiply basis vectors by input direction. preserve vertical velocity
        p.velocity = Vector3(0,p.velocity.y,0) + Vector3(p.basis.x * moveDirXComponent + p.basis.z * p.moveDir.y).limit_length() * movementSpeed
        #apply gravity acceleration. apply more strongly if falling
        if (p.velocity.y >= p.STRONGER_DOWNWARD_GRAVITY_THRESHOLD):
            p.velocity += Const.GRAVITY*_delta * Const.GRAVITY_VECTOR
        else:
            p.velocity += Const.GRAVITY*p.STRONGER_GRAVITY_MULTIPLIER*_delta * Const.GRAVITY_VECTOR

func get_current_move_speed() -> float:
    if pb.sprint.active:
        return p.SPRINT_SPEED
    elif pb.some([&"crouch", &"squeeze", &"drag", &"film_camera"]):
        return p.SLOWED_SPEED
    elif pb.grab.active:
        return p.GRAB_SPEED
    elif pb.crawl.active:
        return p.EXTRA_SLOW_SPEED
    else:
        return p.PLAYER_SPEED
