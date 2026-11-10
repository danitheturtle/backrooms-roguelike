class_name UnstuckBehavior
extends PlayerBehavior

const cannotTransitionFrom: Array[StringName] = [&"vault", &"climb"]

var exceptedBodies: Dictionary[CollisionObject3D, bool]

func reinit() -> void:
    active = false
    exceptedBodies = {}

func start_action() -> void:
    if active: return
    active = true
    var collidingBodies: Dictionary[CollisionObject3D, bool] = p.get_colliding_bodies()
    for nextCollider: CollisionObject3D in collidingBodies.keys():
        if nextCollider.get_collision_layer_value(1):
            exceptedBodies[nextCollider] = true
            nextCollider.add_collision_exception_with(p)

func process_action(_delta: float) -> void:
    if !active || pb.some(cannotTransitionFrom): return
    var remainingColliders: Dictionary[CollisionObject3D, bool] = p.get_colliding_bodies()
    for nextException: CollisionObject3D in exceptedBodies.keys():
        if !remainingColliders.has(nextException):
            nextException.remove_collision_exception_with(p)
            exceptedBodies.erase(nextException)
    if exceptedBodies.size() == 0:
        stop_action()
