class_name Rope
extends Area3D

@export var radius: float = 0.01

@export_group("Refs")
@export var anchor: RopeAnchor
@export var path: Path3D
@export var firstSegmentCollider: CollisionShape3D
@export var firstSegmentMesh: MeshInstance3D

var _cachedLengthToPivot: float = 0.0
var pivotArm: Vector3 = Vector3.ZERO
var pivotArmLength: float = 0.0
var pivotArmDir: Vector3 = Vector3.ZERO

var segmentColliders: Array[CollisionShape3D] = []
var segmentMeshes: Array[MeshInstance3D] = []

var pivotPoint: Vector3:
    get: return path.to_global(path.curve.get_point_position(path.curve.point_count - 2))
    set(newPivot): path.curve.set_point_position(path.curve.point_count - 2, path.to_local(newPivot))

var lastPoint: Vector3:
    get: return lastPoint
    set(newPoint):
        lastPoint = newPoint
        path.curve.set_point_position(path.curve.point_count - 1, path.to_local(newPoint))
        pivotArm = newPoint - pivotPoint
        pivotArmLength = pivotArm.length()
        pivotArmDir = pivotArm / pivotArmLength
        update_segment_shape(path.curve.point_count - 2)
        remove_excess_shapes()

var lastPointBelowPivot: bool:
    get: return lastPoint.y < pivotPoint.y

var length: float:
    get: return _cachedLengthToPivot + pivotArmLength

func _ready() -> void:
    # newly created curve has no points
    while path.curve.point_count < 2:
        path.curve.add_point(Vector3.ZERO)
    firstSegmentCollider.shape.height = radius * 2.0
    firstSegmentCollider.shape.radius = radius
    firstSegmentMesh.mesh.height = radius * 2.0
    firstSegmentMesh.mesh.radius = radius
    update_all_segment_shapes()

func update_cached_length() -> void:
    _cachedLengthToPivot = 0.0
    for i: int in path.curve.point_count - 2:
        _cachedLengthToPivot += (path.to_global(path.curve.get_point_position(i)) - path.to_global(path.curve.get_point_position(i+1))).length()

func update_all_segment_shapes() -> void:
    if segmentColliders.size() == 0:
        segmentColliders.append(firstSegmentCollider)
    if segmentMeshes.size() == 0:
        segmentMeshes.append(firstSegmentMesh)
    for i: int in path.curve.point_count-1:
        if segmentColliders.size() - 1 < i:
            var newShape = firstSegmentCollider.shape.duplicate()
            var newCollider = firstSegmentCollider.duplicate()
            newCollider.shape = newShape
            segmentColliders.append(newCollider)
            add_child(newCollider)
        if segmentMeshes.size() - 1 < i:
            var newMesh = firstSegmentMesh.mesh.duplicate()
            var newMeshInstance = firstSegmentMesh.duplicate()
            newMeshInstance.mesh = newMesh
            segmentMeshes.append(newMeshInstance)
            add_child(newMeshInstance)
        update_segment_shape(i)
    remove_excess_shapes()

func update_segment_shape(_index: int) -> void:
    var segmentPos1: Vector3 = path.curve.get_point_position(_index)
    var segmentPos2: Vector3 = path.curve.get_point_position(_index + 1)
    var segmentVector: Vector3 = segmentPos2 - segmentPos1
    var segmentOrigin = segmentPos1 + segmentVector / 2.0
    var segmentLength: float = segmentVector.length()
    if segmentLength <= 0.001: return
    var segmentQuaternion: Quaternion = Quaternion(Vector3.UP, segmentVector / segmentLength)
    segmentColliders[_index].transform.origin = segmentOrigin
    segmentMeshes[_index].transform.origin = segmentOrigin
    segmentColliders[_index].shape.height = segmentLength
    segmentMeshes[_index].mesh.height = segmentLength + radius * 2.0
    segmentColliders[_index].quaternion = segmentQuaternion
    segmentMeshes[_index].quaternion = segmentQuaternion

func remove_excess_shapes() -> void:
    while segmentColliders.size() > path.curve.point_count-1:
        segmentColliders.pop_back().queue_free()
    while segmentMeshes.size() > path.curve.point_count-1:
        segmentMeshes.pop_back().queue_free()

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
