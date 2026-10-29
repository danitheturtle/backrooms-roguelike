class_name ShoveBehavior
extends PlayerBehavior

func process_action(_delta: float) -> void:
    # shove any rigidbodies
    for i in p.get_slide_collision_count():
        var collision = p.get_slide_collision(i)
        var collider = collision.get_collider()
        if collider is RigidBody3D:
            var oppositeCollisionDir = -collision.get_normal()
            oppositeCollisionDir.y = 0
            var velocityInShoveDir = max(
                p.velocity.dot(oppositeCollisionDir) - collider.linear_velocity.dot(oppositeCollisionDir),
                0.0
            )
            var massRatio = min(1.0, p.PLAYER_MASS / collider.mass)
            var shoveForce = p.SHOVING_FORCE * massRatio
            collider.apply_impulse(oppositeCollisionDir * velocityInShoveDir * shoveForce, collision.get_position() - collider.global_position)
