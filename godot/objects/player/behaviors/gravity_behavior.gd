class_name GravityBehavior
extends PlayerBehavior

const cannotTransitionFrom: Array[StringName] = [&"climb", &"vault"]

func can_act() -> bool:
    return pb.none(cannotTransitionFrom)

func process_action(_delta: float) -> void:
    # apply gravity, skipping for behaviors that directly manipulate position
    if can_act():
        #apply gravity acceleration. apply more strongly if falling
        p.velocity += get_gravity_acceleration() * _delta

## expose core functionality so other behaviors can conditionally apply it
func get_gravity_acceleration() -> Vector3:
    if (p.velocity.y >= p.STRONGER_DOWNWARD_GRAVITY_THRESHOLD):
        return Const.GRAVITY * Const.GRAVITY_VECTOR
    else:
        return Const.GRAVITY * p.STRONGER_GRAVITY_MULTIPLIER * Const.GRAVITY_VECTOR
