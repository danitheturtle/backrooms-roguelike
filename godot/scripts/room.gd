extends Node3D
class_name Room

const RoomDefinition = preload("res://scripts/room_definition.gd")

# room placed manually and is not part of level generation
@export var excludeFromGeneration: bool = false
# before room spawns it has custom sub-generation to run
@export var hasSubRandomization: bool = false
@export var spawnWeight: float = 1.0
@export var onlySpawnAfterNIterations: int = 0

@onready var colliders: Node3D = $Colliders
@onready var lights: Node3D = $Lights
@onready var props: Node3D = $Props
@onready var bounds: Area3D = $Bounds
@onready var connections: Node3D = $Connections

# Returns an array of RoomDefinition objects telling the level generator how this room can be used.
# the level generator should pass the room definition it wants to the setup() function
func get_room_definitions() -> Array[RoomDefinition]:
    if excludeFromGeneration: return []
    var thisRoomDefinition = RoomDefinition.new()
    thisRoomDefinition.spawnWeight = spawnWeight
    thisRoomDefinition.onlySpawnAfterNIterations = onlySpawnAfterNIterations
    # TODO include bounds
    
    # some rooms can define multiple shapes
    return [thisRoomDefinition]

# called after initialization but before being added to the tree. Make wall holes, add sub-props, etc
func setup(_definition: RoomDefinition) -> void:
    if hasSubRandomization: self.shuffle()

# called during setup, or manually, to 
func shuffle() -> void:
    pass
