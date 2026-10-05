@tool
extends Node3D
class_name Room

var editorHelper: RoomEditorHelper = null

# every room scene in the game has a unique name
@export var uniqueName: StringName = ""
# change environmental ambient based on number of active lights
@export var affectsAmbient: bool = true
# more than 1 definition requires custom room class inheriting this one
@export var definitionCount: int = 1
# should the first definition's non-baked props be copied to other definitions
@export var copyFirstDefinitionProps: bool = true
# every room definition levelgen can instantiate using this scene
@export var definitions: Array[RoomDefinition] = []
# manually bake without saving
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

# runtime calculated
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
                connectors.set(NodePath(str(nextSubPath) + "/" + str(nextSubConnectorPath)),
                               nextSubRoom.connectors[nextSubConnectorPath])

func _enter_tree() -> void:
    parentRoom = Utils.get_parent_of_type(self, Room)
    if parentRoom != null: isSubRoom = true

func _ready() -> void:
    if Engine.is_editor_hint():
        if !isSubRoom && uniqueName != "":
            if editorHelper == null:
                editorHelper = RoomEditorHelper.new(self)
            if definitions.size() == 0:
                editorHelper.bake_room_definitions()
                editorHelper.persist_definitions()
    else:
        # hole-punch connectors
        await get_tree().process_frame
        for nextConnector: RoomConnector in connectors.values():
            if nextConnector.doesNotConnect: continue
            nextConnector.build_connectors()

func try_bake_definitions() -> void:
    if editorHelper != null: editorHelper.bake_room_definitions()

# called after initialization but before being added to the tree
func setup(_generatedRoom: GeneratedRoom) -> void:
    var chosenDefinition = definitions[_generatedRoom.indexInScene]
    LevelManager.roomInstances.set(_generatedRoom.roomInstanceId, self)
    apply_room_dynamics(chosenDefinition.dynamicRoomData)
    # setup sub-rooms first. not sure if needed?
    # for nextSubRoom: Room in subRooms: nextSubRoom.setup(_generatedRoom)
    transform.origin = _generatedRoom.placedPosition
    transform.basis = Basis.looking_at(_generatedRoom.placedForwardNormal)
    for nextConnectorPath: NodePath in _generatedRoom.generatedConnectors.keys():
        var nextConnector = get_node(nextConnectorPath)
        if nextConnector == null:
            print("extra connector found in room definition, probably stale baked definition: ", str(nextConnectorPath))
            continue
        var nextGeneratedProps = _generatedRoom.generatedConnectors[nextConnectorPath]
        nextConnector.generatedProps = nextGeneratedProps
        LevelManager.connectorInstances.set(nextGeneratedProps.connectorInstanceId, nextConnector)
    # TODO place props
    # TODO wire up puzzles
    # if sub-random elements, shuffle them
    if chosenDefinition.hasSubRandomization: shuffle()
    # get ambient light level based on number of active lights and their intensities. An approximation for bounce light
    if affectsAmbient:
        var lightNodes: Array = Utils.get_children_of_type(get_node("%Lights"), Light)
        calculatedAmbient = 0.0
        for nextLight: Light in lightNodes:
            if nextLight.lightOn: calculatedAmbient += 0.05
        calculatedAmbient = min(calculatedAmbient, Const.AMBIENT_MAX)

# get room dynamics for a given definition index. only used in dynamic rooms, intentionally blank
# called definitionCount times; map index to full range of values for room
func get_dynamics_for_index(_index: int) -> Dictionary[StringName, Variant]: return {}

# called during setup to adjust room based on chosen definition. more complex dynamic rooms are
# expected to override this
func apply_room_dynamics(dynamics: Dictionary[StringName, Variant]):
    for nextDynamicsKey in dynamics:
        self[nextDynamicsKey] = dynamics[nextDynamicsKey]

# called during setup to randomize stuff in the room and spawn props
func shuffle() -> void: pass
