@tool
class_name ConnectorEditorHelper

var parent: RoomConnector
var adjacentDetector: Area3D
var adjacentCollider: CollisionShape3D
var staticBody: StaticBody3D
var collider: CollisionShape3D
var mesh: MeshInstance3D

func _init(_parent: RoomConnector) -> void:
    parent = _parent
    var container: Node = parent.get_parent()
    if container != null:
        if !container.is_editable_instance(parent):
            container.set_editable_instance(parent, true)
    var allChildren := parent.get_children()
    for nextChild in allChildren:
        if nextChild is StaticBody3D:
            staticBody = nextChild
            collider = staticBody.get_child(0)
        elif nextChild is MeshInstance3D:
            mesh = nextChild
        elif nextChild is Area3D:
            adjacentDetector = nextChild
            adjacentCollider = adjacentDetector.get_child(0)

func bake_connector_definition() -> ConnectorDefinition:
    var definition: ConnectorDefinition = parent.definition
    if definition == null: return null
    definition.name = parent.name
    definition.position = parent.transform.origin
    definition.depth = parent.globalDepth
    var localCornerMin: Vector3
    var localCornerMax: Vector3
    if parent is WallConnector:
        definition.size = Vector2(adjacentCollider.shape.size.x, adjacentCollider.shape.size.y)
        definition.normal = -parent.transform.basis.z
        localCornerMin = -0.5 * Vector3(definition.size.x, definition.size.y, 0.0)
        localCornerMax = 0.5 * Vector3(definition.size.x, definition.size.y, 0.0)
    else:
        definition.size = Vector2(adjacentCollider.shape.size.x, adjacentCollider.shape.size.z)
        definition.normal = Vector3.UP if parent is CeilingConnector else Vector3.DOWN
        localCornerMin = -0.5 * Vector3(definition.size.x, 0.0, definition.size.y)
        localCornerMax = 0.5 * Vector3(definition.size.x, 0.0, definition.size.y)
    ## translate to room-local space from connector-local space
    definition.cornerMin = parent.transform.origin + parent.transform.basis * localCornerMin
    definition.cornerMax = parent.transform.origin + parent.transform.basis * localCornerMax
    var aabbStart = definition.cornerMin + 0.25*definition.normal
    var aabbEnd = definition.cornerMax - 0.25*definition.normal
    definition.aabb = AABB(aabbStart, aabbEnd - aabbStart).abs()
    # TODO:
    definition.distFromFloor = 0.0
    definition.bordersCeiling = false
    return definition

func update_connector_width(newValue: int, axis: StringName):
    var newWidth: float = float(newValue) * Const.VOXEL
    collider.shape.size[axis] = newWidth
    adjacentCollider.shape.size[axis] = newWidth
    mesh.mesh.size.x = newWidth

func update_connector_height(newValue: int, axis: StringName):
    var newHeight: float = float(newValue) * Const.VOXEL
    collider.shape.size[axis] = newHeight
    adjacentCollider.shape.size[axis] = newHeight
    mesh.mesh.size.y = newHeight

func update_connector_depth(newValue: float, axis: StringName):
    var newDepth: float = float(newValue) * Const.VOXEL
    mesh.position[axis] = newDepth
    collider.shape.size[axis] = abs(newDepth)
    collider.position[axis] = newDepth / 2.0
