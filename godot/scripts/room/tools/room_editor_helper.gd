class_name RoomEditorHelper

var parent: Room
var connectors: Dictionary[StringName, RoomConnector]
var boundsArea: Area3D
var definitions: Array[RoomDefinition]

func _init(_parent: Room):
    parent = _parent
    update_refs()

func update_refs() -> void:
    connectors = parent.connectors
    definitions = parent.definitions
    boundsArea = parent.boundsArea

func bake_room_definitions() -> void:
    if parent.isSubRoom: return #sub-rooms don't get baked
    update_refs()
    var connectorDefinitions: Dictionary[StringName, ConnectorDefinition] = {}
    var allBiomes: Dictionary[Const.BiomeType, bool] = {}
    for nextConnector: RoomConnector in connectors.values():
        nextConnector.editorHelper.bake_connector_definition()
        nextConnector.definition.partOfRoomName = parent.uniqueName
        connectorDefinitions[nextConnector.name] = nextConnector.definition
        allBiomes[nextConnector.definition.biome] = true
    var approximateAABB: AABB = AABB(Vector3.ZERO,Vector3.ZERO)
    var boundingAABBs: Array[AABB] = []
    for nextBounds in boundsArea.get_children():
        if nextBounds is CollisionShape3D:
            var newBoundingBox = AABB(nextBounds.transform.origin - (nextBounds.shape.size / 2.0), nextBounds.shape.size)
            approximateAABB = approximateAABB.merge(newBoundingBox)
            boundingAABBs.append(newBoundingBox)
    # TODO: multiple unique defs with size-adjusted connections. gonna have to run some sort of subprocess
    for definitionIndex: int in definitions.size():
        definitions[definitionIndex].sceneName = parent.uniqueName
        definitions[definitionIndex].scenePath = EditorInterface.get_edited_scene_root().scene_file_path
        definitions[definitionIndex].indexInScene = definitionIndex
        definitions[definitionIndex].connectors = connectorDefinitions
        definitions[definitionIndex].biomes = allBiomes
        definitions[definitionIndex].approximateBounds = approximateAABB
        definitions[definitionIndex].bounds = boundingAABBs
        definitions[definitionIndex].dynamicRoomData = {} # TODO not used yet
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

func persist_definitions() -> void:
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
