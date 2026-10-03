@tool
extends Node3D
class_name Room

var editorHelper: RoomEditorHelper = null

@export var uniqueName: StringName = ""
@export var affectsAmbient: bool = true
@export var definitions: Array[RoomDefinition] = []
@export_tool_button("Bake Definitions") var bakeRoomDefinition = try_bake_definitions

# node refs
var colliders: Node3D
var lights: Node3D
var props: Node3D
var boundsArea: Area3D
var connectors: Dictionary[NodePath, RoomConnector]
var subRooms: Array[Room]

# per-instance levelgen output
var generatedProps: GeneratedRoom = null
var instanceId: StringName:
    get:
        if generatedProps == null: return ""
        return generatedProps.roomInstanceId

# calculated
var parentRoom: Room = null
var isSubRoom: bool = false
var calculatedAmbient: float = -1.0 # off by default

func _notification(what: int):
    if uniqueName == "base": return
    match what:
        Node.NOTIFICATION_SCENE_INSTANTIATED:
            grab_refs()
        NOTIFICATION_EDITOR_PRE_SAVE:
            if editorHelper != null && !isSubRoom:
                editorHelper.bake_room_definitions()
                editorHelper.persist_definitions()

func grab_refs() -> void:
    colliders = get_node("%Colliders")
    lights = get_node("%Lights")
    props = get_node("%Props")
    boundsArea = get_node("%Bounds")
    connectors = {}
    subRooms = []
    for nextConnector in get_node("%Connectors").get_children():
        if nextConnector is RoomConnector:
            connectors.set(get_path_to(nextConnector), nextConnector)
    for nextSubRoom in get_node("%SubRooms").get_children():
        if nextSubRoom is Room:
            subRooms.append(nextSubRoom)
            var nextSubPath = get_path_to(nextSubRoom)
            for nextSubConnectorPath: NodePath in nextSubRoom.connectors.keys():
                connectors.set(
                    NodePath(str(nextSubPath) + "/" + str(nextSubConnectorPath)),
                    nextSubRoom.connectors[nextSubConnectorPath]
                )

func _enter_tree() -> void:
    parentRoom = Utils.get_parent_of_type(self, Room)
    if parentRoom != null: isSubRoom = true

func _ready() -> void:
    if Engine.is_editor_hint() && !isSubRoom && uniqueName != "base":
        if editorHelper == null: editorHelper = RoomEditorHelper.new(self)
        if definitions.size() == 0:
            editorHelper.bake_room_definitions()
            editorHelper.persist_definitions()
    # TODO get all object spawn locations

func try_bake_definitions() -> void:
    if editorHelper != null: editorHelper.bake_room_definitions()

# called after initialization but before being added to the tree. Make wall holes, add sub-props, etc
func setup(_generatedRoom: GeneratedRoom) -> void:
    # setup sub-rooms first
    for nextSubRoom: Room in subRooms: nextSubRoom.setup(_generatedRoom)
    transform.origin = _generatedRoom.placedPosition
    transform.basis = Basis.looking_at(_generatedRoom.placedForwardNormal)
    for nextConnectorName in _generatedRoom.generatedConnectors.keys():
        var nextGeneratedProps = _generatedRoom.generatedConnectors[nextConnectorName]
        var nextConnector = connectors[nextConnectorName]
        # TODO wire up connector stuff
        pass
    # TODO place props
    # TODO wire up puzzles
    # if sub-random elements, shuffle them
    if definitions[_generatedRoom.indexInScene].hasSubRandomization: shuffle()
    # hole-punch connectors
    for nextConnector: RoomConnector in connectors.values():
        nextConnector.build_connectors()
    # get ambient light level based on number of active lights and their intensities. An approximation for bounce light
    if affectsAmbient:
        var lightNodes: Array = Utils.get_children_of_type(get_node("%Lights"), Light)
        calculatedAmbient = 0.0
        for nextLight: Light in lightNodes:
            if nextLight.lightOn: calculatedAmbient += 0.05
        calculatedAmbient = min(calculatedAmbient, Const.AMBIENT_MAX)

# called during setup to randomize stuff in the room and spawn props
func shuffle() -> void:
    pass
