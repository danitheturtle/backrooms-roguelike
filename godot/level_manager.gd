extends Node3D
class_name LevelManager

signal level_ready

const RoomDefinition = preload("res://scripts/room_definition.gd")

const rooms = {
    "tutorial": preload("res://rooms/room_tutorial/room_tutorial.tscn"),
    "square_small": preload("res://rooms/room_square_small/room_square_small.tscn")
}

@onready var player: Player = $Player

var loadedRooms: Array[Room] = []

func reinit() -> void:
    for nextLoadedRoom in loadedRooms:
        nextLoadedRoom.free()
    # TODO: clear generated level state
    if player != null:
        player.reinit()

func load_tutorial() -> void:
    if rooms["tutorial"].can_instantiate():
        var tutorialRoom := rooms["tutorial"].instantiate()
        tutorialRoom.setup(RoomDefinition.new())
        finish_loading_tutorial.call_deferred(tutorialRoom)
func finish_loading_tutorial(newRoom: Room):
    add_child(newRoom)
    loadedRooms.append(newRoom)
    level_ready.emit()

func generate_initial_level() -> void:
    level_ready.emit()
