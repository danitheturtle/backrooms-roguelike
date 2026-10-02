@tool
extends Node3D
class_name Room

var editorHelper: RoomEditorHelper = null

@export var uniqueName: StringName = ""
@export var definitions: Array[RoomDefinition] = []

@export_tool_button("Bake Definitions") var bakeRoomDefinition = try_bake_definitions
@export var needsBaked: bool = false
# controls whether entering this room causes an ambience change. usually toggled off for sub-rooms
@export var affectsAmbient: bool = true

# node refs
var colliders: Node3D
var lights: Node3D
var props: Node3D
var boundsArea: Area3D
var connectors: Dictionary[StringName, RoomConnector]
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
    match what:
        Node.NOTIFICATION_SCENE_INSTANTIATED:
            post_init()
        NOTIFICATION_EDITOR_PRE_SAVE:
            if needsBaked && editorHelper != null:
                editorHelper.bake_room_definitions()
            editorHelper.persist_definitions()

func post_init() -> void:
    colliders = get_node("%Colliders")
    lights = get_node("%Lights")
    props = get_node("%Props")
    boundsArea = get_node("%Bounds")
    connectors = {}
    subRooms = []
    for nextConnector in get_node("%Connectors").get_children():
        if nextConnector is RoomConnector: connectors.set(nextConnector.name, nextConnector)
    for nextSubRoom in get_node("%SubRooms").get_children():
        if nextSubRoom is Room: subRooms.append(nextSubRoom)
    parentRoom = Utils.get_parent_of_type(self, Room)
    if parentRoom != null: isSubRoom = true

func _ready() -> void:
    if colliders == null: post_init()
    if Engine.is_editor_hint():
        if editorHelper == null: editorHelper = RoomEditorHelper.new(self)
        if definitions.size() == 0 && !isSubRoom:
            definitions.append(RoomDefinition.new())
            editorHelper.bake_room_definitions()
            editorHelper.persist_definitions()
    # TODO get all object spawn locations

func try_bake_definitions() -> void:
    if editorHelper != null:
        editorHelper.bake_room_definitions()
        needsBaked = false

#func get_all_connectors() -> Array:
    #var returnedRoomConnectors = []
    #for nextSubRoom: Room in subRooms:
        #var subConnectors = nextSubRoom.get_all_connectors()
        #returnedRoomConnectors.append_array(subConnectors)
    #for nextConnector: RoomConnector in Utils.get_children_of_type(connectors, RoomConnector):
        #returnedRoomConnectors.append(RoomConnectorDefinition.new(nextConnector))
    #return returnedRoomConnectors

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
