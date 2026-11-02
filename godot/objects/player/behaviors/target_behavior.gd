class_name TargetBehavior
extends PlayerBehavior

const cannotTransitionFrom: Array[StringName] = [&"film_camera"]

# TODO other types of targetable objects
var ref: Holdable
var targetRayCast: RayCast3D
var targetedPoint: Vector3

## target behavior uses ref to determine whether its active
func get_active() -> bool: return ref != null

func set_active(_nextVal: bool) -> void: pass

func player_ready() -> void:
    targetRayCast = p.get_node("Camera/TargetRayCast")
    targetRayCast.target_position.z = -p.TARGETING_DISTANCE
    targetedPoint = Vector3.ZERO

func reinit() -> void: stop_action()

func can_act() -> bool:
    return pb.none(cannotTransitionFrom) && (pb.drag.can_act() || pb.grab.can_act())

func start_action() -> void: pass

func process_action(_delta: float) -> void:
    if can_act():
        var nextTargetRef = targetRayCast.get_collider()
        if ref != nextTargetRef:
            stop_action()
            if (nextTargetRef is Holdable):
                ref = nextTargetRef
                targetedPoint = targetRayCast.get_collision_point()
                ref.apply_hover_material()

func stop_action() -> void:
    if ref != null: ref.clear_hover_material()
    ref = null

# some non-holdable things like buttons might be actavatable in states where holding isn't possible
func stop_if_target_is_holdable():
    if ref is Holdable: stop_action()
