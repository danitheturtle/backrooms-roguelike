class_name ConnectorDefinition
extends Resource

static var instanceCounter: int = 0
var connectorInstanceId: StringName = "connector_-1"
var parentRoomInstanceId: StringName = "room_-1"

func _init() -> void:
    connectorInstanceId = "connector_" + str(instanceCounter)
    instanceCounter += 1

###
### Set In Editor
###
# Almost always SIMPLE. Level generator can adjust to be higher, but not lower, specificity
@export var initialType: Const.ConnectorType = Const.ConnectorType.SIMPLE
# Almost always EMPTY.
@export var initialSubType: Const.ConnectorSubType = Const.ConnectorSubType.EMPTY
# if true, room supports spawning a prop in front of this connection to block it
@export var blockable: bool = false
# Whether a connector is lockble is defined by its ConnectorType. If false and  level gen picks 
# a higher connector type, this can become true
var lockable: bool:
    get: return initialType >= Const.ConnectorType.NULL_ZONE
# Each connection layer in a room is mutually inaccessible (unbreakable glass, 
# large drops that can't be jumped, etc.)
@export var layer: int = 1
# Connectors are in a biome. A room is a transition room when it has connectors in different biomes
@export var biome: Const.BiomeType = Const.BiomeType.LEVEL_0

###
### Baked
###
# name of this connection in the room scene. unique per room
var name: StringName = ""
# Which room is this connector in? unique name
var partOfRoomName: StringName = ""
# center position of this connector in room-local space
var position: Vector3 = Vector3.ZERO
# 3d position of 2d connector rect on surface of bounds. Garunteed to be on voxel grid
var cornerMin: Vector3 = Vector3.ZERO
var cornerMax: Vector3 = Vector3.ZERO
# direction connector is facing on surface of bounds
var normal: Vector3 = Vector3.FORWARD
# depth of this connector (from visible collision surface to edge of room bounds)
var depth: float = Const.HALF_VOXEL
# width / height of connector surface
var size: Vector2 = Vector2.ZERO
# distance to the floor from the lowest point on the connector surface
var distFromFloor: float = 0.0
var bordersCeiling: bool = false

# debug to confirm things get baked correctly. will go away
var aabb: AABB = AABB()

func get_generated_instance(_parentInstanceId: StringName) -> GeneratedConnector:
    return GeneratedConnector.new(self, _parentInstanceId)
