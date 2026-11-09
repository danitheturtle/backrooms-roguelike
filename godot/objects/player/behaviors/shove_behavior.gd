class_name ShoveBehavior
extends PlayerBehavior

const cannotTransitionFrom: Array[StringName] = [&"climb", &"vault"]

func can_act() -> bool:
    return pb.none(cannotTransitionFrom)

func process_action(_delta: float) -> void:
    if !can_act(): return
    ## shove any rigidbodies
    var collisionCount: int = p.get_slide_collision_count()
    for i: int in collisionCount:
        var collision: KinematicCollision3D = p.get_slide_collision(i)
        var subCollisionCount: int = collision.get_collision_count()
        for j: int in subCollisionCount:
            var collider = collision.get_collider(j)
            if collider is RigidBody3D && collider != pb.drag.draggedRef:
                var oppositeCollisionDir = -collision.get_normal(j)
                oppositeCollisionDir.y = 0
                var velocityInShoveDir = max(
                    p.velocity.dot(oppositeCollisionDir) - collider.linear_velocity.dot(oppositeCollisionDir),
                    0.0
                )
                # spread player impulse force across every sub collision
                var massRatio = min(1.0, p.PLAYER_MASS / subCollisionCount / collider.mass )
                var shoveForce = p.SHOVING_FORCE * massRatio
                collider.apply_impulse(oppositeCollisionDir * velocityInShoveDir * shoveForce, collision.get_position(j) - collider.global_position)
