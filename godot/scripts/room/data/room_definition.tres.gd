class_name RoomDefinition
extends Resource

# Room-local space is defined relative to the room's origin which is always Vector3.ZERO
# External transformations should only be applied to the room and they will automatically cascade
# all values here will remain in room-local space which makes it easy to calculate
# global coords for any of the values in this data structure

# Called by level generator to get a levelgen output object
func get_generated_instance() -> GeneratedRoom:
    var newGeneratedRoom = GeneratedRoom.new(self)
    for nextConnectorPath: NodePath in connectors.keys():
        var newGeneratedConnector = connectors[nextConnectorPath].get_generated_instance(newGeneratedRoom.roomInstanceId)
        newGeneratedRoom.generatedConnectors[nextConnectorPath] = newGeneratedConnector
    return newGeneratedRoom

###
### ROOM EDITOR
###
# pre-levelgen : room placed manually and is not part of level generation
@export var excludeFromGeneration: bool = false

# post-levelgen : before room spawns it has custom sub-generation to run
@export var hasSubRandomization: bool = false

# controls room rarity. range and representative values TBD
@export var spawnWeight: float = 1.0

# controls how late-game the room is. Mainly used for exits and big weenies.
# Range and representative values TBD
# After this iteration, levelgen should slowly ramp room spawn weight from 0
# to its stored value. playtest how quickly this happens
@export var minSpawnIteration: int = 0

# if above 0, limits number of times this room can spawn in a given run
@export var runInstanceLimit: int = 0

# if above 0, only appears n times per savegame. probably only exits
# when one of these is passed back by levelgen, room is removed from input list
@export var saveInstanceLimit: int = 0

# set of puzzle objects the level generator can force-spawn in this room to prevent puzzle lockouts
# TODO add to bake system once object spawners can inform pipeline
@export var canSpawnGameplayProp: Dictionary[Const.GameplayPropType, bool] = {}

###
### BAKED
###
@export_group("Baked")
# unique name for room scene
@export var sceneName: StringName = ""
# room scene path for instantiation
@export var scenePath: String = ""
# this definition's index in the room's array of definitions
@export var indexInScene: int = 0
# biomes this room is a part of. if more than one, this is a transition room
@export var biomes: Dictionary[Const.BiomeType, bool] = {}
# A single AABB that fits all smaller bounding boxes inside it. Useful for very fast checks
@export var approximateBounds: AABB = AABB(Vector3.ZERO,Vector3.ZERO)
# AABB ordered array in room-local space of room extents. Garunteed to be on voxel grid
# if size() == 1 then approximateBounds is exact and identical to bounds[0]
@export var bounds: Array[AABB] = []
# Room connectors. Every connector is a surface on the face of a bounds AABB
@export var connectors: Dictionary[NodePath, ConnectorDefinition] = {}
# Used to tell dynamic scenes how to spawn. A single scene defining multiple rooms will create 
# multiple room definitions. At instantiation time, that scene creates a specific room based on 
# what's stored here
@export var dynamicRoomData: Dictionary[StringName, Variant] = {}

var isTransitionRoom: bool: get = get_is_transition_room
func get_is_transition_room() -> bool: return biomes.keys().size() > 1
