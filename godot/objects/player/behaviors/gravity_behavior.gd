class_name GravityBehavior
extends PlayerBehavior

const cannotTransitionFrom: Array[StringName] = [&"climb", &"vault"]

func can_act() -> bool:
    return pb.none(cannotTransitionFrom)

func process_action(_delta: float) -> void:
    # apply gravity, skipping for behaviors that directly manipulate position
    if can_act():
        #apply gravity acceleration. apply more strongly if falling
        if (p.velocity.y >= p.STRONGER_DOWNWARD_GRAVITY_THRESHOLD):
            p.velocity += Const.GRAVITY * _delta * Const.GRAVITY_VECTOR
        else:
            p.velocity += Const.GRAVITY * p.STRONGER_GRAVITY_MULTIPLIER * _delta * Const.GRAVITY_VECTOR
