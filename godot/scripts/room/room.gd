@tool
extends Node3D
class_name Room

@export var definitions: Array[RoomDefinition] = []

@export_tool_button("Bake Room Definitions") var bakeRoomDefinition = bake_room_definition
@export var needsBaked: bool = false

# controls whether entering this room causes an ambience change. usually toggled off for sub-rooms
@export var affectsAmbient: bool = true

# node refs
var colliders: Node3D
var lights: Node3D
var props: Node3D
var bounds: Area3D
var connectors: Node3D
var subRooms: Array

# calculated at runtime
var parentRoom: Room = null
var isSubRoom: bool = false
var calculatedAmbient: float = -1.0 # off by default

func _notification(what: int):
    match what:
        Node.NOTIFICATION_SCENE_INSTANTIATED:
            post_init()
        NOTIFICATION_EDITOR_PRE_SAVE:
            if needsBaked: bake_room_definition()

func post_init() -> void:
    colliders = get_node("%Colliders")
    lights = get_node("%Lights")
    props = get_node("%Props")
    bounds = get_node("%Bounds")
    connectors = get_node("%Connectors")
    subRooms = Utils.get_children_of_type(get_node("%SubRooms"), Room)
    parentRoom = Utils.get_parent_of_type(self, Room)
    if parentRoom != null: isSubRoom = true

func _ready() -> void:
    if colliders == null: post_init()
    if Engine.is_editor_hint():
        if definitions.size() == 0 && !isSubRoom:
            definitions.append(RoomDefinition.new())
            bake_room_definition()
            persist_definitions()
    # TODO get all object spawn locations

func bake_room_definition() -> void:
    if isSubRoom: return #sub-rooms don't get baked
    var connectorDefinitions: Dictionary[StringName, ConnectorDefinition] = {}
    for nextConnector in connectors.get_children():
        connectorDefinitions[nextConnector.name] = nextConnector.definition
    for definitionIndex: int in definitions.size():
        definitions[definitionIndex].indexInScene = definitionIndex
        definitions[definitionIndex].connectors = connectorDefinitions

# Returns an array of RoomDefinition objects telling the level generator how this room can be used.
# the level generator should pass the room definition it wants to the setup() function
#func get_room_definitions() -> Array[RoomDefinition]:
    #if excludeFromGeneration || isSubRoom: return []
    #var thisRoomDefinition = RoomDefinition.new(roomId)
    ## pass generator weights from editor
    #thisRoomDefinition.spawnWeight = spawnWeight
    #thisRoomDefinition.onlySpawnAfterNIterations = onlySpawnAfterNIterations
    #
    ## define canSpawnObject dict
    #thisRoomDefinition.canSpawnObject = get_can_spawn_objects()
    #
    ## Only parent room bounds are used
    ## bounds should never have rotation / scale. safe to use position as is
    #for nextBounds in bounds.get_children():
        #if nextBounds is CollisionShape3D:
            #var newBoundingBox = AABB(nextBounds.position - (nextBounds.shape.size / 2.0), nextBounds.shape.size)
            #thisRoomDefinition.approximateBounds.merge(newBoundingBox)
            #thisRoomDefinition.bounds.append(newBoundingBox)
    #
    #var allConnectors: Array = get_all_connectors()
    #for nextConnector in allConnectors:
        #var atBoundsEdge = true
        #for nextBounds: AABB in thisRoomDefinition.bounds:
            ## re-create connector's adjacent AABB which is larger than a flat plane
            #var quarterVoxelNormal = (10.0*nextConnector.normal).limit_length(Const.QUARTER_VOXEL)
            #var connectorPos: Vector3 = nextConnector.cornerMin + quarterVoxelNormal
            #var connectorEnd: Vector3 = nextConnector.cornerMax - quarterVoxelNormal
            #nextConnector.aabb = AABB(connectorPos, connectorEnd - connectorPos).abs()
            #if nextBounds.encloses(nextConnector.aabb):
                #atBoundsEdge = false
                #break
        #if atBoundsEdge: thisRoomDefinition.connectors.append(nextConnector)
    #return [thisRoomDefinition]

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
        var nextConnector = connectors.get_node(NodePath(nextConnectorName))
        # TODO wire up connector stuff
        pass
    # TODO place props
    # TODO wire up puzzles
    # if sub-random elements, shuffle them
    if definitions[_generatedRoom.indexInScene].hasSubRandomization: shuffle()
    # hole-punch connectors
    for nextConnector: RoomConnector in Utils.get_children_of_type(connectors, RoomConnector):
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

# editorOnly
func persist_definitions() -> void:
    if !Engine.is_editor_hint(): return
    var editedRoomFolder = EditorInterface.get_edited_scene_root().scene_file_path.get_base_dir()
    var definitionsFolder = editedRoomFolder + "/defs"
    var shouldUpdateFilesystem = false
    if not DirAccess.dir_exists_absolute(definitionsFolder):
        var dirCreateError = DirAccess.make_dir_absolute(definitionsFolder)
        if dirCreateError != OK:
            print("could not create room definitions directory", dirCreateError)
            return
        shouldUpdateFilesystem = true
    for definitionIndex: int in definitions.size():
        var nextDefinition = definitions[definitionIndex]
        if nextDefinition.resource_path.get_base_dir() != definitionsFolder:
            var destinationPath = definitionsFolder + "/definition_" + str(definitionIndex) + ".tres"
            var saveError = ResourceSaver.save(
                nextDefinition,
                destinationPath
            )
            if saveError != OK:
                print("could not save room definition " + str(definitionIndex), saveError)
                return
            definitions[definitionIndex] = load(destinationPath)
            shouldUpdateFilesystem = true
    if shouldUpdateFilesystem: EditorInterface.get_resource_filesystem().scan()
