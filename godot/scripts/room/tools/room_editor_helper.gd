class_name RoomEditorHelper

var room: Room
var connectors: Dictionary[NodePath, RoomConnector]
var boundsArea: Area3D
var definitions: Array[RoomDefinition]

func _init(_room: Room):
    room = _room
    update_refs()

func update_refs() -> void:
    connectors = room.connectors
    definitions = room.definitions
    boundsArea = room.boundsArea

func bake_room_definitions() -> void:
    if room.isSubRoom: return #sub-rooms don't get baked
    update_refs()
    # ensure at least one room definition
    if definitions.size() == 0: definitions.append(RoomDefinition.new())
    var approximateAABB: AABB = AABB(Vector3.ZERO,Vector3.ZERO)
    var boundingAABBs: Array[AABB] = []
    # calculate AABB for all bounds
    for nextBounds in boundsArea.get_children():
        if nextBounds is CollisionShape3D:
            var newBoundingBox = AABB(nextBounds.transform.origin - (nextBounds.shape.size / 2.0), nextBounds.shape.size)
            approximateAABB = approximateAABB.merge(newBoundingBox)
            boundingAABBs.append(newBoundingBox)
    var connectorDefinitions: Dictionary[NodePath, ConnectorDefinition] = {}
    var allBiomes: Dictionary[Const.BiomeType, bool] = {}
    # generator only cares about connectors on room boundary
    for nextConnector: RoomConnector in connectors.values():
        nextConnector.editorHelper.bake_connector_definition()
        var nextConnectorDefinition = nextConnector.definition
        var atBoundsEdge = true
        for nextBoundingAABB: AABB in boundingAABBs:
            if nextBoundingAABB.encloses(nextConnectorDefinition.aabb):
                atBoundsEdge = false
                break
        if atBoundsEdge:
            connectorDefinitions[nextConnector.definition.pathInRoom] = nextConnector.definition
            allBiomes[nextConnector.definition.biome] = true
    # TODO: multiple unique defs with size-adjusted connections. gonna have to run some sort of subprocess
    for definitionIndex: int in room.definitions.size():
        definitions[definitionIndex].sceneName = room.uniqueName
        definitions[definitionIndex].scenePath = EditorInterface.get_edited_scene_root().scene_file_path
        definitions[definitionIndex].indexInScene = definitionIndex
        definitions[definitionIndex].connectors = connectorDefinitions
        definitions[definitionIndex].biomes = allBiomes
        definitions[definitionIndex].approximateBounds = approximateAABB
        definitions[definitionIndex].bounds = boundingAABBs
        definitions[definitionIndex].dynamicRoomData = {} # TODO not used yet

func persist_definitions() -> void:
    if room.isSubRoom: return #sub-rooms don't get baked
    update_refs()
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
