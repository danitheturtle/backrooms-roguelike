@tool
extends Node3D
class_name Room

var editorHelper: RoomEditorHelper = null

# every room scene in the game has a unique name based on its filename
var roomName: StringName = ""
# change environmental ambient based on number of active lights
@export var affectsAmbient: bool = true
# more than 1 definition requires custom room class inheriting this one
@export var definitionCount: int = 1
# should the first definition's non-baked props be copied to other definitions
@export var copyFirstDefinitionProps: bool = true
# every room definition levelgen can instantiate using this scene
@export var definitions: Array[RoomDefinition] = []:
    set(newDefinitionsArray):
        # ensure loaded definitions have not been file corrupted
        for i: int in range(newDefinitionsArray.size()-1, -1, -1):
            if !is_instance_valid(newDefinitionsArray[i]):
                newDefinitionsArray.remove_at(i)
        definitions = newDefinitionsArray
# manually bake
@export_tool_button("Bake Definitions") var bakeRoomDefinition = try_bake_definitions
# clear baked data, including from disk
@export_tool_button("Clear Definitions") var clearRoomDefinition = try_clear_definitions

# node refs
var colliders: Node3D
var lights: Node3D
var props: Node3D
var boundsArea: Area3D
var connectors: Dictionary[NodePath, RoomConnector]
var subRooms: Array[Room]

# per-instance levelgen output
var generatedConnector: GeneratedRoom = null
var instanceId: StringName:
    get:
        if generatedConnector == null: return ""
        return generatedConnector.roomInstanceId

# runtime calculated
var parentRoom: Room = null
var isSubRoom: bool = false
var calculatedAmbient: float = -1.0 # off by default

func _notification(what: int):
    if roomName == "base": return
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
        if !isSubRoom && editorHelper == null:
            editorHelper = RoomEditorHelper.new(self)

func try_bake_definitions() -> void:
    if editorHelper != null: editorHelper.bake_room_definitions()

func try_clear_definitions() -> void:
    if editorHelper != null: editorHelper.clear_room_definitions()

# called after initialization but before being added to the tree
func setup(_generatedRoom: GeneratedRoom) -> void:
    var chosenDefinition = definitions[_generatedRoom.indexInScene]
    LevelManager.roomInstances.set(_generatedRoom.roomInstanceId, self)
    apply_room_dynamics(chosenDefinition.dynamicRoomData)
    # setup sub-rooms first. not sure if needed?
    # for nextSubRoom: Room in subRooms: nextSubRoom.setup(_generatedRoom)
    transform.origin = Utils.voxel_to_world(_generatedRoom.placedPosition)
    transform.basis = Basis.looking_at(Const.CardinalVector[_generatedRoom.placedNormal])
    for nextGeneratedConnector: GeneratedConnector in _generatedRoom.generatedConnectors:
        var nextConnector = get_node(nextGeneratedConnector.pathInRoom)
        if nextConnector == null:
            print("connector from room definition not found in scene, probably stale baked definition: ", str(nextGeneratedConnector.pathInRoom))
            continue
        nextConnector.generatedConnector = nextGeneratedConnector
        LevelManager.connectorInstances.set(nextGeneratedConnector.connectorInstanceId, nextConnector)
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
