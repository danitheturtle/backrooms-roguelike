class_name ConnectorDefinition
extends Resource

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
var lockable: bool: get = get_lockable
func get_lockable() -> bool:
    return initialType >= Const.ConnectorType.NULL_ZONE
# Each connection layer in a room is mutually inaccessible (unbreakable glass, 
# large drops that can't be jumped, etc.)
@export var layer: int = 1
# Connectors are in a biome. A room is a transition room when it has connectors in different biomes
@export var biome: Const.BiomeType = Const.BiomeType.LEVEL_0

###
### Baked
###
@export_group("Baked")
# how to get this connector by calling get_node() on root room
@export var pathInRoom: NodePath = ""
# center position of this connector in room-local space
@export var position: Vector3 = Vector3.ZERO
# depth of this connector (from visible collision surface to edge of room bounds)
@export var depth: float = Const.HALF_VOXEL
# direction connector is facing on surface of bounds
@export var normal: Vector3 = Vector3.ZERO
# width / height of connector surface
@export var size: Vector2 = Vector2.ZERO
# 3d position of 2d connector rect on surface of bounds. Garunteed to be on voxel grid
@export var cornerMin: Vector3 = Vector3.ZERO
@export var cornerMax: Vector3 = Vector3.ZERO
# distance to the floor from the lowest point on the connector surface
@export var distFromFloor: float = 0.0
@export var bordersCeiling: bool = false
# AABB used to detect other connectors. Centered with WxHxD = Size.x,size.y,0.5
@export var aabb: AABB = AABB()

func get_generated_instance(_parentInstanceId: StringName) -> GeneratedConnector:
    return GeneratedConnector.new(self, _parentInstanceId)
