@tool
class_name ConnectorEditorHelper

var room: Room
var connector: RoomConnector
var adjacentCollider: CollisionShape3D
var staticBody: StaticBody3D
var collider: CollisionShape3D
var mesh: MeshInstance3D

var editedPathToConnector: NodePath = ""
var isInSubRoom: bool

func _init(_connector: RoomConnector) -> void:
    connector = _connector
    # connectors must always be editable relative to parent room for sizing props to work. enforce here
    var container: Node = connector.get_parent()
    if is_instance_valid(container):
        if !container.is_editable_instance(connector):
            container.set_editable_instance(connector, true)
            connector.set_display_folded(true)
            connector.emit_signal("script_changed")
    # wire up selection to always select parent
    EditorInterface.get_selection().connect('selection_changed', on_selection_changed)
    # grab refs to relevant child nodes
    var allChildren := connector.get_children()
    for nextChild in allChildren:
        if nextChild is StaticBody3D:
            staticBody = nextChild
            collider = staticBody.get_child(0)
        elif nextChild is MeshInstance3D:
            mesh = nextChild
        elif nextChild is Area3D:
            adjacentCollider = nextChild.get_child(0)
    # detect 
    room = Utils.get_parent_of_type(connector, Room)
    var editedRoot = EditorInterface.get_edited_scene_root()
    isInSubRoom = room != editedRoot
    editedPathToConnector = editedRoot.get_path_to(connector, true)

func on_selection_changed():
    if connector.selectableChildren: return
    var editorSelection = EditorInterface.get_selection()
    var selected = editorSelection.get_selected_nodes()
    if selected.size() == 1 && connector.is_ancestor_of(selected[0]):
        var selectedChild = selected[0]
        editorSelection.add_node(connector)
        editorSelection.remove_node(selectedChild)
        connector.set_display_folded(true)
        connector.emit_signal("script_changed")

func on_connector_ready() -> void:
    if connector.definition == null: connector.definition = ConnectorDefinition.new()
    if isInSubRoom && connector.definition.pathInRoom != editedPathToConnector:
        connector.definition = connector.definition.duplicate()
        connector.definition.pathInRoom = editedPathToConnector
    connector.voxelWidth = connector.voxelWidth
    connector.voxelHeight = connector.voxelHeight
    connector.voxelDepth = connector.voxelDepth

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

func bake_connector_definition() -> ConnectorDefinition:
    var definition: ConnectorDefinition = connector.definition
    if definition == null: return null
    definition.pathInRoom = editedPathToConnector
    # get transform that turns connector-local space into room-local space
    var relativeTransform: Transform3D = Transform3D()
    if isInSubRoom:
        var nextParentRoom = room
        while nextParentRoom != null:
            relativeTransform = nextParentRoom.transform * relativeTransform
            nextParentRoom = Utils.get_parent_of_type(nextParentRoom, Room)
    var connectorRelativeTransform = relativeTransform * connector.transform
    # bake props into definition. translate into room-local space
    definition.position = connectorRelativeTransform.origin
    definition.depth = connector.globalDepth
    var localCornerMin: Vector3
    var localCornerMax: Vector3
    if connector is WallConnector:
        definition.size = Vector2(adjacentCollider.shape.size.x, adjacentCollider.shape.size.y)
        definition.normal = -connectorRelativeTransform.basis.z
        localCornerMin = -0.5 * Vector3(definition.size.x, definition.size.y, 0.0)
        localCornerMax = 0.5 * Vector3(definition.size.x, definition.size.y, 0.0)
    else:
        definition.size = Vector2(adjacentCollider.shape.size.x, adjacentCollider.shape.size.z)
        definition.normal = Vector3.UP if connector is CeilingConnector else Vector3.DOWN
        localCornerMin = -0.5 * Vector3(definition.size.x, 0.0, definition.size.y)
        localCornerMax = 0.5 * Vector3(definition.size.x, 0.0, definition.size.y)
    definition.cornerMin = connectorRelativeTransform * localCornerMin
    definition.cornerMax = connectorRelativeTransform * localCornerMax
    var aabbStart = definition.cornerMin + 0.25*definition.normal
    var aabbEnd = definition.cornerMax - 0.25*definition.normal
    definition.aabb = AABB(aabbStart, aabbEnd - aabbStart).abs()
    # TODO:
    definition.distFromFloor = 0.0
    definition.bordersCeiling = false
    return definition
