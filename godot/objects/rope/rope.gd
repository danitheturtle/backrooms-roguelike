class_name Rope
extends Area3D

@export var anchor: RopeAnchor
@export var path: Path3D

var _cachedLengthToPivot: float = 0.0
var lastSegment: Vector3 = Vector3.ZERO
var lastSegmentLength: float = 0.0
var length: float:
    get: return _cachedLengthToPivot + lastSegmentLength

func _ready() -> void:
    # newly created curve has no points
    while path.curve.point_count < 2:
        path.curve.add_point(Vector3.ZERO)
    # a pre-placed rope always has a valid path
    # build segment shapes for every segment on path
    for nextSegmentIndex in path.curve.point_count-1:
        pass

func update_last_segment_length() -> void:
    lastSegment = path.to_global(path.curve.get_point_position(path.curve.point_count-1)) - path.to_global(path.curve.get_point_position(path.curve.point_count-2))
    lastSegmentLength = lastSegment.length()

func update_cached_length() -> void:
    _cachedLengthToPivot = 0.0
    for i: int in path.curve.point_count-2:
        _cachedLengthToPivot += (path.to_global(path.curve.get_point_position(i)) - path.to_global(path.curve.get_point_position(i+1))).length()

func get_nearest_control_point(_global_pos: Vector3) -> int:
    var nearestDistSq: float = 999999.0
    var nearestIndex: int = -1
    for i: int in path.curve.point_count:
        var nextPos = path.to_global(path.curve.get_point_position(i))
        var nextDistSq = (_global_pos - nextPos).length_squared()
        if nextDistSq < nearestDistSq:
            nearestDistSq = nextDistSq
            nearestIndex = i
    return nearestIndex
