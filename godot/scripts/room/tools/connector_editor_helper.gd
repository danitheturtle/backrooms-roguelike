@tool
class_name ConnectorEditorHelper

var room: Room
var editedRoot: Node
var connector: RoomConnector
var adjacentDetector: Area3D
var adjacentCollider: CollisionShape3D
var staticBody: StaticBody3D
var collider: CollisionShape3D
var mesh: MeshInstance3D

var editedPathToConnector: NodePath = ""

func _init(_connector: RoomConnector) -> void:
    connector = _connector
    var container: Node = connector.get_parent()
    if container != null:
        if !container.is_editable_instance(connector):
            container.set_editable_instance(connector, true)
    var allChildren := connector.get_children()
    for nextChild in allChildren:
        if nextChild is StaticBody3D:
            staticBody = nextChild
            collider = staticBody.get_child(0)
        elif nextChild is MeshInstance3D:
            mesh = nextChild
        elif nextChild is Area3D:
            adjacentDetector = nextChild
            adjacentCollider = adjacentDetector.get_child(0)

func on_connector_ready() -> void:
    room = Utils.get_parent_of_type(connector, Room)
    editedRoot = EditorInterface.get_edited_scene_root()
    editedPathToConnector = editedRoot.get_path_to(connector, true)
    if connector.definition == null: connector.definition = ConnectorDefinition.new()
    var isInSubRoom: bool = room != editedRoot
    if isInSubRoom && connector.definition.pathInRoom != editedPathToConnector:
        connector.definition = connector.definition.duplicate()
        connector.definition.pathInRoom = editedPathToConnector
    connector.voxelWidth = connector.voxelWidth
    connector.voxelHeight = connector.voxelHeight
    connector.voxelDepth = connector.voxelDepth
    
func bake_connector_definition() -> ConnectorDefinition:
    var definition: ConnectorDefinition = connector.definition
    if definition == null: return null
    definition.pathInRoom = editedPathToConnector
    # TODO walk up the tree to edited root, applying transforms along the way
    definition.position = connector.transform.origin
    definition.depth = connector.globalDepth
    var localCornerMin: Vector3
    var localCornerMax: Vector3
    if connector is WallConnector:
        definition.size = Vector2(adjacentCollider.shape.size.x, adjacentCollider.shape.size.y)
        definition.normal = -connector.transform.basis.z
        localCornerMin = -0.5 * Vector3(definition.size.x, definition.size.y, 0.0)
        localCornerMax = 0.5 * Vector3(definition.size.x, definition.size.y, 0.0)
    else:
        definition.size = Vector2(adjacentCollider.shape.size.x, adjacentCollider.shape.size.z)
        definition.normal = Vector3.UP if connector is CeilingConnector else Vector3.DOWN
        localCornerMin = -0.5 * Vector3(definition.size.x, 0.0, definition.size.y)
        localCornerMax = 0.5 * Vector3(definition.size.x, 0.0, definition.size.y)
    ## translate to room-local space from connector-local space
    definition.cornerMin = connector.transform.origin + connector.transform.basis * localCornerMin
    definition.cornerMax = connector.transform.origin + connector.transform.basis * localCornerMax
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
