extends Node

signal level_ready
signal room_spawned

const roomsDir: String = "res://rooms/"

## load from disk at runtime
var rooms: Dictionary[StringName, PackedScene] = {}
var allDefinitions: Array[RoomDefinition] = []

var generator: TreeLevelGenerator = null
var root: LevelRoot = null
var levelActive: bool = false
var currentLevelSeed: int = 0
var roomInstances: Dictionary[StringName, Room] = {}
var connectorInstances: Dictionary[StringName, RoomConnector] = {}
var generationActive: bool = false
var spawningRoom: bool = false

func _init() -> void:
    generator = TreeLevelGenerator.new()
    load_rooms_from_disk(roomsDir)
    generator.update_definitions(allDefinitions)

# called when a run ends or player switches game modes
func reinit(nextSeed: int = -1) -> void:
    for nextLoadedRoom in roomInstances.values():
        if is_instance_valid(nextLoadedRoom):
            nextLoadedRoom.free()
    roomInstances = {}
    connectorInstances = {}
    levelActive = false
    generationActive = false
    spawningRoom = false
    # reinit player
    if State.player != null:
        State.player.reinit()
    # reset random number gen
    State.rng = RandomNumberGenerator.new()
    if nextSeed != -1:
        State.rng.seed = nextSeed
        currentLevelSeed = nextSeed
    else:
        State.rng.randomize()
        currentLevelSeed = State.rng.seed

func _process(_delta: float) -> void:
    if !levelActive: return
    if generationActive && !spawningRoom && State.player.process_mode != Node.PROCESS_MODE_DISABLED:
        generator.generate_in_radius(Utils.world_to_chunk(State.player.global_position))
        var newlyAddedRoom := generator.resolve_generation()
        if newlyAddedRoom != null:
            place_room_in_level(newlyAddedRoom)

# tutorial is its own game mode since it has no rng
func load_tutorial() -> void:
    var tutorialRoom: Room = rooms["tutorial"].instantiate()
    var tutorialInstance: GeneratedRoom = GeneratedRoom.new(tutorialRoom.definitions[0])
    tutorialRoom.setup(tutorialInstance)
    root.add_child(tutorialRoom)
    tutorialRoom.owner = root
    roomInstances[tutorialInstance.roomInstanceId] = tutorialRoom
    on_level_ready()

# called at the start of a run
func generate_initial_level() -> void:
    var firstRoomInstance: GeneratedRoom = generator.reinit(0, State.rng.seed, 3)
    var firstRoom: Room = rooms[firstRoomInstance.roomName].instantiate()
    firstRoom.setup(firstRoomInstance)
    root.add_child(firstRoom)
    firstRoom.owner = root
    generationActive = true
    on_level_ready()

func on_level_ready() -> void:
    await get_tree().process_frame
    await get_tree().process_frame
    # this causes the player to always spawn at the first and highest PlayerSpawn in the tree
    # the tree can have many player spawns but the first one found is used
    var playerSpawn = Utils.get_child_of_type(root, PlayerSpawn, true)
    if playerSpawn != null && playerSpawn is PlayerSpawn:
        State.player.global_transform = playerSpawn.global_transform
    # Player is disabled by default to prevent physics jank during setup
    State.player.process_mode = Node.PROCESS_MODE_PAUSABLE
    levelActive = true
    level_ready.emit()

func place_room_in_level(nextGeneratedRoom: GeneratedRoom) -> void:
    if !rooms.has(nextGeneratedRoom.roomInstanceId):
        spawn_room(nextGeneratedRoom)

# emits spawned room object once its fully in the world
func spawn_room(_generatedRoom: GeneratedRoom) -> void:
    spawningRoom = true
    var spawnedRoom: Room = rooms[_generatedRoom.roomName].instantiate()
    spawnedRoom.setup(_generatedRoom)
    roomInstances.set(_generatedRoom.roomInstanceId, spawnedRoom)
    var connectorsToUpdate: Array[RoomConnector] = []
    for generatedConnection: GeneratedConnectionPair in _generatedRoom.generatedConnections:
        var nextConnector: RoomConnector = null
        if roomInstances.has(generatedConnection.parentRoomInstanceId):
            var updatedRoom: Room = roomInstances[generatedConnection.parentRoomInstanceId]
            if updatedRoom.connectors.has(generatedConnection.pathInRoom):
                nextConnector = updatedRoom.connectors[generatedConnection.pathInRoom]
                nextConnector.update(generatedConnection)
        elif spawnedRoom.connectors.has(generatedConnection.pathInRoom):
            nextConnector = spawnedRoom.connectors[generatedConnection.pathInRoom]
            nextConnector.setup(generatedConnection)
        if nextConnector == null:
            print("problem creating or updating a connection returned by levelgen: ", str(generatedConnection.pathInRoom))
            continue
        connectorsToUpdate.append(nextConnector)
        connectorInstances.set(generatedConnection.connectorInstanceId, nextConnector)
    root.add_child(spawnedRoom)
    spawnedRoom.owner = root
    # TODO why do we need to wait two frames on room spawn?
    await get_tree().process_frame
    await get_tree().process_frame
    for nextConnector: RoomConnector in connectorsToUpdate:
        nextConnector.build_connectors()
    spawningRoom = false
    room_spawned.emit(spawnedRoom)

func load_rooms_from_disk(_dir: String) -> void:
    var allItems: PackedStringArray = ResourceLoader.list_directory(_dir)
    if allItems.size() == 0: return
    for nextItem: String in allItems:
        if nextItem.ends_with("/") && !nextItem.begins_with("res"):
            load_rooms_from_disk(_dir + nextItem)
        elif nextItem.ends_with(".tscn") && nextItem.begins_with("room"):
            if nextItem == "room_base.tscn": continue
            var nextRoomroomName: StringName = StringName(nextItem.replace("room_", "").replace(".tscn", ""))
            var loadedRoomScene: PackedScene = ResourceLoader.load(_dir + nextItem, "PackedScene")
            rooms.set(nextRoomroomName, loadedRoomScene)
        elif nextItem.ends_with(".tres") && nextItem.begins_with("definition"):
            var loadedDefinition: RoomDefinition = ResourceLoader.load(_dir + nextItem, "RoomDefinition")
            # some definitions are excluded from levelgen. don't include them
            if loadedDefinition.excludeFromGeneration: continue
            allDefinitions.append(loadedDefinition)
