@tool
extends Node3D
class_name Room

@export var definitions: Array[Resource] = []

@export_tool_button("Bake Room Definitions") var bakeRoomDefinition = bake_room_definition
@export var needsBaked: bool = false

# controls whether entering this room causes an ambience change. usually toggled off for sub-rooms
@export var affectsAmbient: bool = true

# node refs grabbed on ready
@onready var colliders: Node3D = $Colliders
@onready var lights: Node3D = $Lights
@onready var props: Node3D = $Props
@onready var bounds: Area3D = $Bounds
@onready var connectors: Node3D = $Connectors
var subRooms = []

# calculated at runtime
var parentRoom: Room = null
var isSubRoom: bool = false
var calculatedAmbient: float = -1.0 # off by default

func _ready() -> void:
    subRooms = Utils.get_children_of_type($SubRooms, Room)
    parentRoom = Utils.get_parent_of_type(self, Room)
    if parentRoom != null: isSubRoom = true
    if Engine.is_editor_hint():
        if definitions.size() == 0 && !isSubRoom:
            definitions.append(RoomDefinition.new())
            bake_room_definition()
            persist_definitions()
    # TODO get all object spawn locations

func _notification(what: int):
    if (what == NOTIFICATION_EDITOR_PRE_SAVE && needsBaked): bake_room_definition()

func bake_room_definition() -> void:
    if isSubRoom: return #sub-rooms don't get baked
    var connectorDefinitions: Dictionary[StringName, ConnectorDefinition] = {}
    for nextConnector in connectors.get_children():
        connectorDefinitions[nextConnector.name] = nextConnector.definition
    definitions[0].connectors = connectorDefinitions

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
    # hole-punch connectors
    #for nextConnector: RoomConnector in Utils.get_children_of_type(connectors, RoomConnector):
        #nextConnector.build_connectors()
    # if sub-random elements, shuffle them
    # TODO let the level generator force-spawn things first
    #if _generatedRoom.hasSubRandomization: self.shuffle()
    # get ambient light level based on number of active lights and their intensities. An approximation for bounce light
    #if affectsAmbient:
        #var lightNodes: Array[Light] = Utils.get_children_of_type(lights, Light)
        #calculatedAmbient = 0.0
        #for nextLight: Light in lightNodes:
            #if nextLight.lightOn: calculatedAmbient += 0.05
        #calculatedAmbient = min(calculatedAmbient, Const.AMBIENT_MAX)

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
