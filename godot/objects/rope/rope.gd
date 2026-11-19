class_name Rope
extends Area3D

const MIN_CONTROL_POINT_GAP_SQ: float = 0.03 * 0.03

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
var wrapUnwrapCooldown: int = 0
var baseMaterialUVScale: Vector3 = Vector3.ONE

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
        update_pivot_arm()
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
    baseMaterialUVScale = firstSegmentMesh.material_override.uv1_scale
    firstSegmentMesh.material_override = firstSegmentMesh.material_override.duplicate()
    firstSegmentMesh.mesh.height = diameter
    firstSegmentMesh.mesh.radius = radius
    unwrapTestShape = CapsuleShape3D.new()
    unwrapTestShape.height = diameter
    unwrapTestShape.radius = radius
    for i: int in lastIndex:
        ensure_shape_for_segment(i)
    lastPoint = path.to_global(path.curve.get_point_position(lastIndex))
    update_cached_length()
    update_all_segment_shapes()

func _physics_process(_delta: float) -> void:
    wrapUnwrapCooldown = max(0, wrapUnwrapCooldown - 1)
    # do not update a rope that is not near the player 
    if (global_position - State.player.global_position).length_squared() - length * length > 1000.0: return
    # if this is not the active rope, check for updates along length every few frames
    # 3 casts per check frame, and a check frame happens every ~7-13 frames. prime number to minimize 
    # number of ropes updating on the same frame

func update_cached_length() -> void:
    _cachedLengthToPivot = 0.0
    for i: int in pivotIndex:
        _cachedLengthToPivot += (path.to_global(path.curve.get_point_position(i)) - path.to_global(path.curve.get_point_position(i+1))).length()

func update_pivot_arm() -> void:
    pivotArm = lastPoint - pivotPoint
    pivotArmLength = pivotArm.length()
    pivotArmDir = pivotArm / pivotArmLength

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
        var newMaterial = firstSegmentMesh.material_override.duplicate()
        var newMeshInstance = firstSegmentMesh.duplicate()
        newMeshInstance.material_override = newMaterial
        newMeshInstance.mesh = newMesh
        segmentMeshes.append(newMeshInstance)
        add_child(newMeshInstance)

func update_segment_shape(_index: int) -> void:
    var segmentPos1: Vector3 = path.curve.get_point_position(_index)
    var segmentPos2: Vector3 = path.curve.get_point_position(_index + 1)
    var segmentVector: Vector3 = segmentPos2 - segmentPos1
    var segmentOrigin = segmentPos1 + segmentVector / 2.0
    var segmentLengthSq: float = segmentVector.length_squared()
    if segmentLengthSq < MIN_CONTROL_POINT_GAP_SQ: return
    var updatedMesh: MeshInstance3D = segmentMeshes[_index]
    var updatedCollider: CollisionShape3D = segmentColliders[_index]
    var segmentLength: float = sqrt(segmentLengthSq)
    var segmentQuaternion: Quaternion = Quaternion(Vector3.UP, segmentVector / segmentLength)
    updatedCollider.quaternion = segmentQuaternion
    updatedCollider.transform.origin = segmentOrigin
    updatedCollider.shape.mid_height = segmentLength
    updatedMesh.mesh.height = segmentLength + diameter
    updatedMesh.material_override.uv1_scale.x = updatedMesh.mesh.radius * 20.0
    updatedMesh.material_override.uv1_scale.y = updatedMesh.mesh.height * 20.0
    updatedMesh.material_override.uv1_scale.z = updatedMesh.mesh.radius * 20.0
    updatedMesh.mesh.request_update()
    updatedMesh.quaternion = segmentQuaternion
    updatedMesh.transform.origin = segmentOrigin

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
    if wrapUnwrapCooldown > 0: return
    var previousPoint = path.to_global(path.curve.get_point_position(_insertBeforeIndex-1))
    var nextPoint = path.to_global(path.curve.get_point_position(_insertBeforeIndex))
    var newControlPoint = _collision.point + _collision.normal * diameter
    var newControlPointLocal: Vector3 = path.to_local(newControlPoint)
    # don't insert new point if the segment would be too short
    var prevToNew: Vector3 = previousPoint - newControlPoint
    var newToNext: Vector3 = newControlPoint - nextPoint
    if prevToNew.length_squared() < MIN_CONTROL_POINT_GAP_SQ || newToNext.length_squared() < MIN_CONTROL_POINT_GAP_SQ:
        return
    path.curve.add_point(newControlPointLocal, Vector3.ZERO, Vector3.ZERO, _insertBeforeIndex)
    ensure_shape_for_segment(_insertBeforeIndex)
    update_segment_shape(_insertBeforeIndex)
    ensure_shape_for_segment(_insertBeforeIndex - 1)
    update_segment_shape(_insertBeforeIndex - 1)
    update_cached_length()
    wrapUnwrapCooldown = 7

## shapecasts between next and previous points. if no collision, removes control point from curve
var unwrapping: bool = false
func try_unwrap_point(_pointIndex: int) -> void:
    if wrapUnwrapCooldown > 0 || _pointIndex > pivotIndex || _pointIndex < 1: return
    # TODO if either length is too close to current point, treat it as the same control point and decrement again
    var previousPoint: Vector3 = path.to_global(path.curve.get_point_position(_pointIndex-1))
    var nextPoint: Vector3 = path.to_global(path.curve.get_point_position(_pointIndex+1))
    
    var unwrapVector: Vector3 = nextPoint - previousPoint
    var unwrapLengthSq: float = unwrapVector.length_squared()
    if unwrapLengthSq < MIN_CONTROL_POINT_GAP_SQ: return
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
        remove_excess_shapes()
        unwrapping = true
        for i: int in range(_pointIndex-1, lastIndex):
            update_segment_shape(i)
        update_cached_length()
    wrapUnwrapCooldown = 7

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
