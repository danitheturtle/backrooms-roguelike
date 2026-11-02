class_name DragBehavior
extends PlayerBehavior

const cannotTransitionFrom: Array[StringName] = [&"grab", &"jump", &"vault", &"crouch", &"crawl", &"squeeze", &"sprint", &"climb", &"film_camera"]

var draggedRef: Holdable
var draggedPoint: Vector3

func get_active() -> bool: return draggedRef != null

func set_active(_nextVal: bool) -> void: pass

func reinit() -> void:
    draggedPoint = Vector3.ZERO
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
    pb.target.ref.on_hold()
    draggedRef = pb.target.ref
    draggedPoint = draggedRef.to_local(pb.target.targetedPoint)
    pb.target.stop_action()

func process_action(_delta: float) -> void:
    if !active: return
    if (p.global_position - (draggedRef.global_position + draggedPoint)).length_squared() > draggedRef.heldDistance * draggedRef.heldDistance:
        stop_action()
    else:
        draggedRef.linear_velocity = Vector3(p.velocity.x, 0.0, p.velocity.z)

func stop_action() -> void:
    if !active: return
    reinit()
    p.grabArm.spring_length = p.TARGETING_DISTANCE
    p.grabArm.shape.radius = p.grabArmShapeRadius
    pb.stand.start_action()
