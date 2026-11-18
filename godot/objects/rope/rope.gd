class_name Rope
extends Area3D

const MIN_CONTROL_POINT_GAP: float = 0.03

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

var diameter: float:
    get: return radius * 2.0

var pointCount: int:
    get: return 0 if path == null || path.curve == null else path.curve.point_count

var pivotIndex: int:
    get: return max(0, pointCount - 2)

var lastIndex: int:
    get: return max(0, pointCount - 1)

var pivotPoint: Vector3:
    get: return path.to_global(path.curve.get_point_position(pivotIndex))
    set(newPivot): path.curve.set_point_position(pivotIndex, path.to_local(newPivot))

var lastPoint: Vector3:
    get: return lastPoint
    set(newPoint):
        lastPoint = newPoint
        path.curve.set_point_position(lastIndex, path.to_local(newPoint))
        pivotArm = newPoint - pivotPoint
        pivotArmLength = pivotArm.length()
        pivotArmDir = pivotArm / pivotArmLength
        update_segment_shape(pivotIndex)

var lastPointBelowPivot: bool:
    get: return lastPoint.y < pivotPoint.y

var length: float:
    get: return _cachedLengthToPivot + pivotArmLength

func _ready() -> void:
    # newly created curve has no points
    while pointCount < 2:
        path.curve.add_point(Vector3.ZERO)
    firstSegmentCollider.shape.height = diameter
    firstSegmentCollider.shape.radius = radius
    firstSegmentMesh.mesh.height = diameter
    firstSegmentMesh.mesh.radius = radius
    update_all_segment_shapes()

func _physics_process(delta: float) -> void:
    # if this is not the active rope, check for updates along length every few frames
    # 3 casts per check frame, and a check frame happens every ~7-13 frames. prime number to minimize 
    # number of ropes updating on the same frame
    # do not update a rope that is not near the player
    pass

func update_cached_length() -> void:
    _cachedLengthToPivot = 0.0
    for i: int in pivotIndex:
        _cachedLengthToPivot += (path.to_global(path.curve.get_point_position(i)) - path.to_global(path.curve.get_point_position(i+1))).length()

func update_all_segment_shapes() -> void:
    if segmentColliders.size() == 0:
        segmentColliders.append(firstSegmentCollider)
    if segmentMeshes.size() == 0:
        segmentMeshes.append(firstSegmentMesh)
    for i: int in lastIndex:
        ensure_shape_for_segment(i)
        update_segment_shape(i)
    remove_excess_shapes()

func ensure_shape_for_segment(_index: int) -> void:
    if segmentColliders.size() - 1 < _index:
        var newShape = firstSegmentCollider.shape.duplicate()
        var newCollider = firstSegmentCollider.duplicate()
        newCollider.shape = newShape
        segmentColliders.append(newCollider)
        add_child(newCollider)
    if segmentMeshes.size() - 1 < _index:
        var newMesh = firstSegmentMesh.mesh.duplicate()
        var newMeshInstance = firstSegmentMesh.duplicate()
        newMeshInstance.mesh = newMesh
        segmentMeshes.append(newMeshInstance)
        add_child(newMeshInstance)

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
    segmentColliders[_index].shape.mid_height = segmentLength
    segmentMeshes[_index].mesh.height = segmentLength + diameter
    segmentColliders[_index].quaternion = segmentQuaternion
    segmentMeshes[_index].quaternion = segmentQuaternion

## assumes shapes are synced with curve already
## index must be 1 less than the max index of the path
func shapecast_segment(_index: int) -> Dictionary:
    if _index >= lastIndex: return {}
    var colliderForCast: CollisionShape3D = segmentColliders[_index]
    var spaceState = get_world_3d().direct_space_state
    var segmentQuery: PhysicsShapeQueryParameters3D = PhysicsShapeQueryParameters3D.new()
    segmentQuery.collision_mask = 0b00000000000000001111
    segmentQuery.exclude = [anchor]
    segmentQuery.shape = colliderForCast.shape
    segmentQuery.transform = Transform3D(colliderForCast.transform.basis, path.to_global(colliderForCast.transform.origin))
    var segmentQueryResult := spaceState.get_rest_info(segmentQuery)
    return segmentQueryResult

func shapecast_last_segment() -> Dictionary:
    return shapecast_segment(pivotIndex)

func wrap_around_geometry(_collision: Dictionary, _insertBeforeIndex: int) -> void:
    var previousPoint = path.to_global(path.curve.get_point_position(_insertBeforeIndex-1))
    var nextPoint = path.to_global(path.curve.get_point_position(_insertBeforeIndex))
    var newControlPoint: Vector3 = path.to_local(_collision.point + _collision.normal * diameter)
    var quarterVoxelSq: float = MIN_CONTROL_POINT_GAP * MIN_CONTROL_POINT_GAP
    if (previousPoint - _collision.point).length_squared() < quarterVoxelSq || (nextPoint - _collision.point).length_squared() < quarterVoxelSq:
        return
    path.curve.add_point(newControlPoint, Vector3.ZERO, Vector3.ZERO, _insertBeforeIndex)
    ensure_shape_for_segment(_insertBeforeIndex - 1)
    update_segment_shape(_insertBeforeIndex - 1)
    ensure_shape_for_segment(_insertBeforeIndex)
    update_segment_shape(_insertBeforeIndex)
    update_cached_length()

func get_nearest_control_point(_global_pos: Vector3) -> int:
    var nearestDistSq: float = 999999.0
    var nearestIndex: int = -1
    for i: int in pointCount:
        var nextPos = path.to_global(path.curve.get_point_position(i))
        var nextDistSq = (_global_pos - nextPos).length_squared()
        if nextDistSq < nearestDistSq:
            nearestDistSq = nextDistSq
            nearestIndex = i
    return nearestIndex

func remove_excess_shapes() -> void:
    while segmentColliders.size() > lastIndex:
        segmentColliders.pop_back().queue_free()
    while segmentMeshes.size() > lastIndex:
        segmentMeshes.pop_back().queue_free()
