extends Node3D
class_name Room

@export var roomId: StringName = ""
# room placed manually and is not part of level generation
@export var excludeFromGeneration: bool = false
# before room spawns it has custom sub-generation to run
@export var hasSubRandomization: bool = false
@export var spawnWeight: float = 1.0
@export var onlySpawnAfterNIterations: int = 0
# controls whether entering this room causes an ambience change. usually toggled off for sub-rooms
@export var affectsAmbient: bool = true

@export_group("Can Spawn Objects", "canSpawn")
@export var canSpawnLadder: bool = false
@export var canSpawnLadderFreestanding: bool = false
@export var canSpawnLadderTall: bool = false
@export var canSpawnObjectPlacementPuzzle: bool = false

# node refs grabbed on ready
@onready var colliders: Node3D = $Colliders
@onready var lights: Node3D = $Lights
@onready var props: Node3D = $Props
@onready var bounds: Area3D = $Bounds
@onready var connectors: Node3D = $Connectors
@onready var subRooms: Array[Room] = Utils.get_children_of_type($SubRooms, Room)

# calculated at runtime
var parentRoom: Room = null
var isSubRoom: bool = false
var calculatedAmbient: float = -1.0 # off by default

func _ready() -> void:
    parentRoom = Utils.get_parent_of_type(self, Room)
    if parentRoom != null: isSubRoom = true
    # TODO get all object spawn locations

# Returns an array of RoomDefinition objects telling the level generator how this room can be used.
# the level generator should pass the room definition it wants to the setup() function
func get_room_definitions() -> Array[RoomDefinition]:
    if excludeFromGeneration || isSubRoom: return []
    var thisRoomDefinition = RoomDefinition.new(roomId)
    # pass generator weights from editor
    thisRoomDefinition.spawnWeight = spawnWeight
    thisRoomDefinition.onlySpawnAfterNIterations = onlySpawnAfterNIterations
    
    # define canSpawnObject dict
    thisRoomDefinition.canSpawnObject = get_can_spawn_objects()
    
    # Only parent room bounds are used
    # bounds should never have rotation / scale. safe to use position as is
    for nextBounds in bounds.get_children():
        if nextBounds is CollisionShape3D:
            var newBoundingBox = AABB(nextBounds.position - (nextBounds.shape.size / 2.0), nextBounds.shape.size)
            thisRoomDefinition.approximateBounds.expand(newBoundingBox)
            thisRoomDefinition.bounds.append(newBoundingBox)
    
    var allConnectors: Array[RoomConnectorDefinition] = get_all_connectors()
    for nextConnector in allConnectors:
        var atBoundsEdge = true
        for nextBounds: AABB in thisRoomDefinition.bounds:
            # re-create connector's adjacent AABB which is larger than a flat plane
            var quarterVoxelNormal = (10.0*nextConnector.normal).limit_length(Const.QUARTER_VOXEL)
            var connectorPos: Vector3 = nextConnector.cornerMin + quarterVoxelNormal
            var connectorEnd: Vector3 = nextConnector.cornerMax - quarterVoxelNormal
            nextConnector.aabb = AABB(connectorPos, connectorEnd - connectorPos).abs()
            if nextBounds.encloses(nextConnector.aabb):
                atBoundsEdge = false
                break
        if atBoundsEdge: thisRoomDefinition.connectors.append(nextConnector)
    return [thisRoomDefinition]

func get_can_spawn_objects() -> Dictionary[StringName,bool]:
    var canSpawnSet: Dictionary[StringName,bool] = {}
    if canSpawnLadder: canSpawnSet.ladder = true
    if canSpawnLadderFreestanding: canSpawnSet.ladderFreestanding = true
    if canSpawnLadderTall: canSpawnSet.ladderTall = true
    if canSpawnObjectPlacementPuzzle: canSpawnSet.objectPlacementPuzzle = true
    return canSpawnSet

func get_all_connectors() -> Array[RoomConnectorDefinition]:
    var returnedRoomConnectors = []
    for nextSubRoom: Room in subRooms:
        var subConnectors = nextSubRoom.get_all_connectors()
        returnedRoomConnectors.append_array(subConnectors)
    for nextConnector: RoomConnector in Utils.get_children_of_type(connectors, RoomConnector):
        returnedRoomConnectors.append(RoomConnectorDefinition.new(nextConnector))
    return returnedRoomConnectors

# called after initialization but before being added to the tree. Make wall holes, add sub-props, etc
func setup(_roomDefinition: RoomDefinition) -> void:
    # setup sub-rooms first
    for nextSubRoom: Room in subRooms: nextSubRoom.setup(_roomDefinition)
    # hole-punch connectors
    for nextConnector: RoomConnector in connectors:
        nextConnector.build_connectors()
    # if sub-random elements, shuffle them
    # TODO let the level generator force-spawn things first
    if hasSubRandomization: self.shuffle()
    # get ambient light level based on number of active lights and their intensities. An approximation for bounce light
    if affectsAmbient:
        var lightNodes = Utils.get_children_of_type(lights, Light)
        calculatedAmbient = 0.0
        for nextLight: Light in lightNodes:
            if nextLight.lightOn: calculatedAmbient += 0.05
        calculatedAmbient = min(calculatedAmbient, Const.AMBIENT_MAX)

# called during setup to randomize stuff in the room and spawn props
func shuffle() -> void:
    pass
