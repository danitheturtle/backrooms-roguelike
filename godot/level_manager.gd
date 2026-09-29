extends Node3D
class_name LevelManager

signal level_ready

const rooms: Dictionary[String, PackedScene] = {
    "tutorial": preload("res://rooms/room_tutorial/room_tutorial.tscn"),
    "four_way": preload("res://rooms/room_four_way/room_four_way.tscn"),
    "all_way": preload("res://rooms/room_all_way/room_all_way.tscn"),
    "nook_with_ramp": preload("res://rooms/room_nook_with_ramp/room_nook_with_ramp.tscn"),
    "test": preload("res://rooms/room_test/room_test.tscn")
}

@onready var player: Player = $Player

var currentLevelSeed: int = 0
var loadedRooms: Array[Room] = []

func _ready() -> void:
    pass
    # TODO give room definitions to the generator

# called when a run ends or player switches game modes
func reinit(nextSeed: int = -1) -> void:
    for nextLoadedRoom in loadedRooms:
        nextLoadedRoom.free()
    loadedRooms = []
    # TODO: clear generated level state
    # reinit player
    if player != null:
        player.reinit()
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
    var tutorialDefinition: RoomDefinition = tutorialRoom.get_room_definitions()[0]
    tutorialRoom.setup(tutorialDefinition)
    await get_tree().process_frame
    add_child(tutorialRoom)
    loadedRooms.append(tutorialRoom)
    # Player is disabled by default to prevent physics jank during setup
    player.process_mode = Node.PROCESS_MODE_PAUSABLE
    level_ready.emit()

# called at the start of a run
func generate_initial_level() -> void:
    var testRoom: Room = rooms["test"].instantiate()
    var testRoomDefinition: RoomDefinition = testRoom.get_room_definitions()[0]
    testRoom.setup(testRoomDefinition)
    # Player is disabled by default to prevent physics jank during setup
    await get_tree().process_frame
    add_child(testRoom)
    loadedRooms.append(testRoom)
    player.process_mode = Node.PROCESS_MODE_PAUSABLE
    level_ready.emit()
