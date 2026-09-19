extends Node3D
class_name LevelManager

signal level_ready

const RoomDefinition = preload("res://scripts/room_definition.gd")

const rooms: Dictionary[String, PackedScene] = {
    "tutorial": preload("res://rooms/room_tutorial/room_tutorial.tscn"),
    "square_small": preload("res://rooms/room_square_small/room_square_small.tscn")
}

@onready var player: Player = $Player

var currentLevelSeed: int = 0
var loadedRooms: Array[Room] = []
var allRoomDefinitions: Array[RoomDefinition] = []

func _ready() -> void:
    for nextRoomName in rooms.keys():
        var temporaryRoomInstance: Room = rooms[nextRoomName].instantiate()
        for nextDefinition in temporaryRoomInstance.get_room_definitions():
            allRoomDefinitions.append(nextDefinition)
        temporaryRoomInstance.free()
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
    tutorialRoom.setup(RoomDefinition.new())
    await get_tree().process_frame
    add_child(tutorialRoom)
    loadedRooms.append(tutorialRoom)
    # Player is disabled by default to prevent physics jank during setup
    player.process_mode = Node.PROCESS_MODE_PAUSABLE
    level_ready.emit()

# called at the start of a run
func generate_initial_level() -> void:
    # Player is disabled by default to prevent physics jank during setup
    player.process_mode = Node.PROCESS_MODE_PAUSABLE
    await get_tree().process_frame
    level_ready.emit()
