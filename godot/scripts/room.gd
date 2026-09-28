extends Node3D
class_name Room

# room placed manually and is not part of level generation
@export var excludeFromGeneration: bool = false
# before room spawns it has custom sub-generation to run
@export var hasSubRandomization: bool = false
@export var spawnWeight: float = 1.0
@export var onlySpawnAfterNIterations: int = 0

@export_group("Can Spawn Objects", "canSpawn")
@export var canSpawnLadder: bool = false
@export var canSpawnLadderFreestanding: bool = false
@export var canSpawnLaddertall: bool = false
@export var canSpawnObjectPlacementPuzzle: bool = false
@export var canSpawnSkeletonKey: bool = false

@onready var colliders: Node3D = $Colliders
@onready var lights: Node3D = $Lights
@onready var props: Node3D = $Props
@onready var bounds: Area3D = $Bounds
@onready var connections: Node3D = $Connections
@onready var subRooms: Node3D = $SubRooms

# Returns an array of RoomDefinition objects telling the level generator how this room can be used.
# the level generator should pass the room definition it wants to the setup() function
func get_room_definitions() -> Array[RoomDefinition]:
    if excludeFromGeneration: return []
    var thisRoomDefinition = RoomDefinition.new()
    # pass generator weights from editor
    thisRoomDefinition.spawnWeight = spawnWeight
    thisRoomDefinition.onlySpawnAfterNIterations = onlySpawnAfterNIterations
    # define canSpawnObject dict
    thisRoomDefinition.canSpawnObject = {
        "ladder": canSpawnLadder,
        "ladderFreestanding": canSpawnLadderFreestanding
    }
    # Only parent room bounds are used
    for nextBounds in bounds.get_children():
        if nextBounds is CollisionShape3D:
            thisRoomDefinition.append_bounds_shape(nextBounds)
    # TODO: also get connections from sub-rooms that lay on the room boundary
    # some rooms can define multiple shapes
    return [thisRoomDefinition]

# called after initialization but before being added to the tree. Make wall holes, add sub-props, etc
func setup(_definition: RoomDefinition) -> void:
    if hasSubRandomization: self.shuffle()
    # get ambient light level based on number of active lights and their intensities. An approximation for bounce light
    

# called during setup, or manually, to 
func shuffle() -> void:
    pass
