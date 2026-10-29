class_name StairstepBehavior
extends PlayerBehavior

const cannotTransitionFrom: Array[StringName] = [&"vault", &"jump", &"crawl", &"squeeze", &"drag", &"grab"]

func can_act() -> bool:
    return pb.none(cannotTransitionFrom) && p.velocity.y <= 0 && p.velocity.length_squared() > 0.05

func process_action(_delta: float) -> void:
    if can_act():
        p.stairSolver.rotation.y = atan2(-p.moveDir.x, -p.moveDir.y)
        var expectedPositionDelta = p.velocity * (0.4 if !p.b.crouch.active else 0.6) * _delta
        var collisionCastVector = Vector3(0,p.MAX_STEP_HEIGHT*1.5, 0)
        var nextPosCollisionCastStart = p.global_transform.translated(expectedPositionDelta + collisionCastVector)
        var collisionResult = KinematicCollision3D.new()
        if p.test_move(nextPosCollisionCastStart, -collisionCastVector, collisionResult):
            var foundCollider = collisionResult.get_collider()
            if ((foundCollider is CollisionObject3D || foundCollider is CSGShape3D) \
                && (foundCollider.get_collision_layer_value(3) || foundCollider.get_collision_layer_value(4))):
                var castHeightTravelled = ((nextPosCollisionCastStart.origin + collisionResult.get_travel()) - p.global_position).y
                if (castHeightTravelled > 0.01 && castHeightTravelled <= p.MAX_STEP_HEIGHT && (collisionResult.get_position() - p.global_position).y <= p.MAX_STEP_HEIGHT):
                    if p.stairRayCast.get_collision_normal().dot(Vector3.UP) < 0.1:
                        p.global_position = nextPosCollisionCastStart.origin + collisionResult.get_travel() + Vector3(0,0.02,0)
