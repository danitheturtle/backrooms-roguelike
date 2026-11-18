class_name Rope
extends Area3D

const MIN_CONTROL_POINT_GAP: float = 0.03
const minControlPointGapSq: float = MIN_CONTROL_POINT_GAP * MIN_CONTROL_POINT_GAP

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
var unwrapTestShape: Shape3D

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
    unwrapTestShape = CapsuleShape3D.new()
    unwrapTestShape.height = diameter
    unwrapTestShape.radius = radius
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
    var segmentLengthSq: float = segmentVector.length_squared()
    if segmentLengthSq < MIN_CONTROL_POINT_GAP * MIN_CONTROL_POINT_GAP: return
    var segmentLength: float = sqrt(segmentLengthSq)
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

func wrap_around_geometry(_collision: Dictionary, _insertBeforeIndex: int) -> void:
    var previousPoint = path.to_global(path.curve.get_point_position(_insertBeforeIndex-1))
    var nextPoint = path.to_global(path.curve.get_point_position(_insertBeforeIndex))
    var newControlPoint: Vector3 = path.to_local(_collision.point + _collision.normal * diameter)
    # don't insert new point if the segment would be too short
    if (previousPoint - _collision.point).length_squared() < minControlPointGapSq || (nextPoint - _collision.point).length_squared() < minControlPointGapSq:
        return
    path.curve.add_point(newControlPoint, Vector3.ZERO, Vector3.ZERO, _insertBeforeIndex)
    ensure_shape_for_segment(_insertBeforeIndex - 1)
    update_segment_shape(_insertBeforeIndex - 1)
    ensure_shape_for_segment(_insertBeforeIndex)
    update_segment_shape(_insertBeforeIndex)
    update_cached_length()

## shapecasts between next and previous points. if no collision, removes control point from curve
func try_unwrap_point(_pointIndex: int) -> void:
    if _pointIndex > pivotIndex || _pointIndex < 1: return
    # TODO if either length is too close to current point, treat it as the same control point and decrement again
    var currentPoint: Vector3 =path.curve.get_point_position(_pointIndex)
    
    var lengthSqToPrevious: float = 0.0
    var decrementBy: int = 1
    var previousPoint: Vector3 = Vector3.INF
    while lengthSqToPrevious < minControlPointGapSq && _pointIndex-decrementBy >= 0:
        previousPoint = path.curve.get_point_position(_pointIndex-decrementBy)
        lengthSqToPrevious = (currentPoint - previousPoint).length_squared()
        decrementBy -= 1
    previousPoint = path.to_global(previousPoint)
    if previousPoint == Vector3.INF: return
    
    #var nextPoint: Vector3 = path.to_global(path.curve.get_point_position(_pointIndex+1))
    
    var lengthSqToNext: float = 0.0
    var incrementBy: int = 1
    var nextPoint: Vector3 = Vector3.INF
    while lengthSqToNext < minControlPointGapSq && _pointIndex+incrementBy <= lastIndex:
        nextPoint = path.curve.get_point_position(_pointIndex+incrementBy)
        lengthSqToNext = (currentPoint - previousPoint).length_squared()
        incrementBy += 1
    nextPoint = path.to_global(nextPoint)
    if nextPoint == Vector3.INF: return
    
    var unwrapVector: Vector3 = nextPoint - previousPoint
    var unwrapLengthSq: float = unwrapVector.length_squared()
    if unwrapLengthSq < MIN_CONTROL_POINT_GAP * MIN_CONTROL_POINT_GAP: return
    var unwrapLength: float = sqrt(unwrapLengthSq)
    var unwrapDir: Vector3 = unwrapVector / unwrapLength
    var spaceState = get_world_3d().direct_space_state
    var unwrapQuery: PhysicsShapeQueryParameters3D = PhysicsShapeQueryParameters3D.new()
    unwrapQuery.collision_mask = 0b00000000000000001111
    unwrapQuery.exclude = [anchor]
    unwrapQuery.shape = unwrapTestShape
    unwrapQuery.shape.mid_height = unwrapLength
    unwrapQuery.transform = Transform3D(Basis(Quaternion(Vector3.UP, unwrapDir)), previousPoint + unwrapVector / 2.0)
    var unwrapQueryResult := spaceState.collide_shape(unwrapQuery)
    if unwrapQueryResult.is_empty():
        path.curve.remove_point(_pointIndex)
        for i: int in range(_pointIndex-1, lastIndex):
            update_segment_shape(i)
        remove_excess_shapes()
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
