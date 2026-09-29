class_name RoomDefinition
extends Resource

# Room-local space is defined relative to the room's origin which is always Vector3.ZERO
# External transformations should only be applied to the room and they will automatically cascade
# all values here will remain in room-local space which makes it easy to calculate
# global coords for any of the values in this data structure
@export var roomID: StringName = ""
# room placed manually and is not part of level generation
@export var excludeFromGeneration: bool = false
# controls room rarity. range and representative values TBD
@export var spawnWeight: float = 1.0
# controls how late-game the room is. Mainly used for exits. Range and representative values TBD
@export var minSpawnIteration: int = 0
# before room spawns it has custom sub-generation to run
@export var hasSubRandomization: bool = false

# set of puzzle objects the level generator can force-spawn in this room to prevent puzzle lockouts
# TODO add to bake system once object spawners con inform pipeline
@export var canSpawnObject: Dictionary[Const.SpawnableType, bool] = {}

###
### LEVEL GENERATOR OUTPUT
###
# set by level generator and used by room sub-generator
@export var placedAtIteration: int = -1
# adjusted prop spawn weight for room sub-generator
@export var propDensity: float = 1.0


###
### BAKED
###
# biomes this room is a part of. if more than one, this is a transition room
var biomes: Dictionary[Const.BiomeType, bool] = {}
var transitionRoom:
    get: return biomes.keys().size() > 1

# A single AABB that fits all smaller bounding boxes inside it. Useful for very fast checks
var approximateBounds: AABB = AABB(Vector3.ZERO,Vector3.ZERO)
# AABB ordered array in room-local space of room extents
var bounds: Array[AABB] = []

# Array of room connectors. Every connector is a surface on the face of a bounds AABB
var connectors: Dictionary[StringName, ConnectorDefinition] = {}

# Used to tell dynamic scenes how to spawn. A single scene defining multiple rooms will create 
# multiple room definitions. At instantiation time, that scene creates a specific room based on 
# what's stored here
var dynamicRoomProps: Dictionary[StringName, Variant] = {}
