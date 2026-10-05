class_name RoomEditorHelper

var room: Room
var uniqueName: StringName
var roomScenePath: String
var connectors: Dictionary[NodePath, RoomConnector]
var boundsArea: Area3D
var definitionCount: int
var definitions: Array[RoomDefinition]

func _init(_room: Room):
    room = _room
    roomScenePath = EditorInterface.get_edited_scene_root().scene_file_path 
    update_refs()

func update_refs() -> void:
    uniqueName = room.uniqueName
    connectors = room.connectors
    definitionCount = room.definitionCount
    definitions = room.definitions
    boundsArea = room.boundsArea

func bake_room_definitions() -> void:
    if room.isSubRoom: return #sub-rooms don't get baked
    update_refs()
    # ensure definitions exist
    for i in definitionCount:
        if definitions.size() - 1 > i && definitions[i] == null:
            definitions[i] = RoomDefinition.new()
        else:
            definitions.append(RoomDefinition.new())
    definitions.resize(definitionCount)
    var firstDefinition = definitions[0]
    # loop backwards so scene gets saved with props from index 0
    for definitionIndex in range(definitionCount-1, -1, -1):
        var nextDefinition = definitions[definitionIndex]
        # most rooms don't have dynamics but this is where the sauce happens for rooms that do
        var nextDynamics := room.get_dynamics_for_index(definitionIndex)
        room.apply_room_dynamics(nextDynamics)
        # calculate AABBs from bounds
        var approximateAABB: AABB = AABB(Vector3.ZERO,Vector3.ZERO)
        var boundingAABBs: Array[AABB] = []
        for nextBounds in boundsArea.get_children():
            if nextBounds is CollisionShape3D:
                boundingAABBs.append(AABB(nextBounds.transform.origin - (nextBounds.shape.size / 2.0), nextBounds.shape.size))
                approximateAABB = approximateAABB.merge(boundingAABBs[boundingAABBs.size()-1])
        var connectorDefinitions: Dictionary[NodePath, ConnectorDefinition] = {}
        var allBiomes: Dictionary[Const.BiomeType, bool] = {}
        # generator only cares about connectors on room boundary
        for nextConnector: RoomConnector in connectors.values():
            nextConnector.editorHelper.bake_connector_definition()
            # duplicate definition to be saved with room def. actual connector definitions are saved with definition index 0
            var nextConnectorDefinition := nextConnector.definition
            if definitionIndex != 0: nextConnectorDefinition = nextConnectorDefinition.duplicate()
            var atBoundsEdge = true
            for nextBoundingAABB: AABB in boundingAABBs:
                if nextBoundingAABB.encloses(nextConnectorDefinition.aabb):
                    atBoundsEdge = false
                    break
            if atBoundsEdge:
                connectorDefinitions[nextConnectorDefinition.pathInRoom] = nextConnectorDefinition
                allBiomes[nextConnectorDefinition.biome] = true
        nextDefinition.sceneName = uniqueName
        nextDefinition.scenePath = roomScenePath
        nextDefinition.indexInScene = definitionIndex
        nextDefinition.connectors = connectorDefinitions
        nextDefinition.biomes = allBiomes
        nextDefinition.approximateBounds = approximateAABB
        nextDefinition.bounds = boundingAABBs
        nextDefinition.dynamicRoomData = nextDynamics
        if room.copyFirstDefinitionProps && definitionIndex != 0:
            nextDefinition.excludeFromGeneration = firstDefinition.excludeFromGeneration
            nextDefinition.spawnWeight = firstDefinition.spawnWeight
            nextDefinition.minSpawnIteration = firstDefinition.minSpawnIteration
            nextDefinition.hasSubRandomization = firstDefinition.hasSubRandomization
            nextDefinition.canSpawnGameplayProp = firstDefinition.canSpawnGameplayProp
    notify_property_list_changed()

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
        var destinationPath = definitionsFolder + "/definition_" + str(definitionIndex) + ".tres"
        if nextDefinition.resource_path != destinationPath:
            var saveError = ResourceSaver.save(nextDefinition, destinationPath)
            if saveError != OK:
                print("could not save room definition " + str(definitionIndex), saveError)
                return
            definitions[definitionIndex] = load(destinationPath)
            shouldUpdateFilesystem = true
    if shouldUpdateFilesystem:
        EditorInterface.get_resource_filesystem().scan()
    notify_property_list_changed()
