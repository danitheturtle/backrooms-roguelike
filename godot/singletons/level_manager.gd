extends Node

signal level_ready

# TODO build dynamically at runtime from saved files in threaded resource loader
const rooms: Dictionary[StringName, PackedScene] = {
    "tutorial": preload("res://rooms/room_tutorial/room_tutorial.tscn"),
    "four_way": preload("res://rooms/room_four_way/room_four_way.tscn"),
    "all_way": preload("res://rooms/room_all_way/room_all_way.tscn"),
    "nook_with_ramp": preload("res://rooms/room_nook_with_ramp/room_nook_with_ramp.tscn"),
    "test": preload("res://rooms/room_test/room_test.tscn")
}
# TODO build dynamically at runtime from saved files in threaded resource loader
const allDefinitions: Array[RoomDefinition] = [
    preload("res://rooms/room_all_way/defs/definition_0.tres"),
    preload("res://rooms/room_four_way/defs/definition_0.tres"),
    preload("res://rooms/room_nook_with_ramp/defs/definition_0.tres"),
    preload("res://rooms/room_test/defs/definition_0.tres"),
    preload("res://rooms/room_tutorial/defs/definition_0.tres")
]

var root: LevelRoot = null
var currentLevelSeed: int = 0
var roomInstances: Dictionary[StringName, Room] = {}
var connectorInstances: Dictionary[StringName, RoomConnector] = {}

# called when a run ends or player switches game modes
func reinit(nextSeed: int = -1) -> void:
    for nextLoadedRoom in roomInstances.values():
        if is_instance_valid(nextLoadedRoom):
            nextLoadedRoom.free()
    roomInstances = {}
    connectorInstances = {}
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

# tutorial is its own game mode since it has no rng
func load_tutorial() -> void:
    var tutorialRoom: Room = rooms["tutorial"].instantiate()
    var tutorialInstance: GeneratedRoom = tutorialRoom.definitions[0].get_generated_instance()
    tutorialRoom.setup(tutorialInstance)
    await get_tree().process_frame
    add_child(tutorialRoom)
    # Player is disabled by default to prevent physics jank during setup
    State.player.process_mode = Node.PROCESS_MODE_PAUSABLE
    level_ready.emit()

# called at the start of a run
func generate_initial_level() -> void:
    var testRoom: Room = rooms["test"].instantiate()
    var testRoomInstance: GeneratedRoom = testRoom.definitions[0].get_generated_instance()
    testRoom.setup(testRoomInstance)
    await get_tree().process_frame
    add_child(testRoom)
    # Player is disabled by default to prevent physics jank during setup
    State.player.process_mode = Node.PROCESS_MODE_PAUSABLE
    level_ready.emit()
