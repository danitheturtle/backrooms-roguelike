class_name RopeBehavior
extends PlayerBehavior

const cannotTransitionFrom: Array[StringName] = [&"climb", &"film_camera", &"drag", &"squeeze", &"vault"]
const mutuallyExclusiveWith: Array[StringName] = [&"flashlight", &"jump"]

var ropeRef: Rope
var ropePath: Path3D
var ropeCurve: Curve3D

func get_active() -> bool:
    return ropeRef != null

func reinit() -> void:
    active = false
    ropeRef = null

func can_act() -> bool:
    if (p.adjacentRef is Rope && p.adjacentRef != ropeRef && !active && pb.none(cannotTransitionFrom)):
        if pb.crouch.active && !p.can_shape_change(): return false
        return true
    return false

func start_action() -> void:
    if active: return
    ropeRef = p.adjacentRef
    ropePath = Utils.get_child_of_type(ropeRef, Path3D)
    ropeCurve = ropePath.curve
    if ropeCurve.point_count < 2:
        ropeCurve.add_point(ropeRef.to_local(p.global_position))
    active = true
    
    pb.stop(mutuallyExclusiveWith)

func process_action(_delta: float) -> void:
    if !active: return
    ropeCurve.set_point_position(ropeCurve.point_count-1, ropeRef.to_local(p.global_position))

func stop_action() -> void:
    if !active: return
    reinit()
