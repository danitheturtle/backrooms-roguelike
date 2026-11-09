class_name DragBehavior
extends PlayerBehavior

const cannotTransitionFrom: Array[StringName] = [&"grab", &"jump", &"vault", &"crouch", &"crawl", &"squeeze", &"sprint", &"climb", &"film_camera"]
const mutuallyExclusiveWith: Array[StringName] = [&"target", &"flashlight"]

var draggedRef: Holdable
var justDragged: bool
var draggedPoint: Vector3

func get_active() -> bool: return draggedRef != null

func set_active(_nextVal: bool) -> void: pass

func reinit() -> void:
    draggedPoint = Vector3.ZERO
    justDragged = false
    if active:
        draggedRef.on_drop()
        draggedRef = null

func can_act() -> bool:
    if (!active && pb.none(cannotTransitionFrom) && pb.jump.onFloorLastFrame):
        return not (pb.target.ref is Holdable && (pb.target.ref.mass > p.MAX_DRAG_MASS || pb.target.ref.mass <= p.MAX_GRAB_MASS))
    else:
        return false

func start_action() -> void:
    if active: return
    draggedRef = pb.target.ref.on_hold(player)
    justDragged = true
    draggedPoint = draggedRef.to_local(pb.target.targetedPoint)
    pb.stop(mutuallyExclusiveWith)

func process_action(_delta: float) -> void:
    if !active: return
    # update dragged ref and use line of sight from raycast to break behavior if level geometry blocks
    var spaceState = p.get_world_3d().direct_space_state
    var dragPointQuery = PhysicsRayQueryParameters3D.create(
        p.camera.global_position,
        draggedRef.global_position,
        p.collision_mask
    )
    dragPointQuery.exclude = [player]
    var dragPointResult = spaceState.intersect_ray(dragPointQuery)
    if !dragPointResult.is_empty() && dragPointResult.collider == draggedRef:
        draggedPoint = dragPointResult.position
    else:
        stop_action()
        return
    if (p.global_position - draggedPoint).length_squared() > draggedRef.heldDistance * draggedRef.heldDistance:
        stop_action()
    else:
        var targetVelocity = Vector3(p.velocity.x, 0.0, p.velocity.z)
        # wait till end of frame for accurate player collision detection
        call_deferred("apply_dragging_force", targetVelocity, _delta)

func stop_action() -> void:
    if !active: return
    reinit()
    pb.stand.start_action()

func apply_dragging_force(_targetVelocity: Vector3, _delta: float) -> void:
    # if player is on top of and supported by dragged object, do nothing
    if !on_top_of_or_below_dragged():
        var currentHorizontalVelocity = Vector3(draggedRef.linear_velocity.x, 0.0, draggedRef.linear_velocity.z)
        var appliedForce = draggedRef.mass * (_targetVelocity - currentHorizontalVelocity) / _delta
        draggedRef.apply_central_force(appliedForce)

func on_top_of_or_below_dragged() -> bool:
    var lastFrameCollisionCount = p.get_slide_collision_count()
    for i: int in lastFrameCollisionCount:
        var nextKinematicCollision: KinematicCollision3D = p.get_slide_collision(i)
        var nextKinematicCollisionCount = nextKinematicCollision.get_collision_count()
        for j: int in nextKinematicCollisionCount:
            if nextKinematicCollision.get_collider(j) is Holdable:
                var dotProduct = nextKinematicCollision.get_normal(j).dot(Vector3.UP)
                if dotProduct > 0.25 || dotProduct < -0.25:
                    return true
    return false
