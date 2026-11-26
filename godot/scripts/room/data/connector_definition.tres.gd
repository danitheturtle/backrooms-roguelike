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

# Whether a connector is lockble is defined by its ConnectorType. If false and level gen picks
# a higher connector type, this can become true
var lockable: bool: get = get_lockable
func get_lockable() -> bool:
    return initialType >= Const.ConnectorType.NULL_ZONE

# Each connection layer in a room is mutually inaccessible (unbreakable glass,
# large drops that can't be jumped, etc.)
@export var layer: int = 1

# Connectors are in a biome. A room is a transition room when it has connectors in different biomes
@export var biome: Const.BiomeType = Const.BiomeType.LEVEL_0

# Selection weight defines how often this connector should be selected for generation relative to
# other connections in the same room. /w value of 0.0 only select as last resort
@export var selectionWeight: float = 1.0

###
### Baked
###
@export_group("Baked")
# how to get this connector by calling get_node() on root room
@export var pathInRoom: NodePath = ""
# direction connector is facing on surface of bounds
@export var normal: Const.CardinalDirection
# 3d voxel position of 2d connector rect on surface of bounds
@export var cornerMin: Vector3i = Vector3i.ZERO
@export var cornerMax: Vector3i = Vector3i.ZERO
# distance to the floor from the lowest point on the connector surface
@export var distFromFloor: float = 0.0
@export var bordersCeiling: bool = false
# AABB used to detect other connectors. Centered with WxHxD = Size.x,size.y,0.5
@export var aabb: AABB = AABB()
