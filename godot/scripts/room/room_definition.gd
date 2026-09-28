class_name RoomDefinition

# Room-local space is defined relative to the room's origin which is always Vector3.ZERO
# External transformations should only be applied to the room and they will automatically cascade
# all values here will remain in room-local space which makes it easy to calculate
# global coords for any of the values in this data structure

var roomSceneName: StringName = ""
# controls room rarity. range and representative values TBD
var spawnWeight: float = 1.0
# controls how late-game the room is. Mainly used for exits. Range and representative values TBD
var onlySpawnAfterNIterations: int = 0

# set of puzzle objects the level generator can force-spawn in this room to prevent puzzle lockouts
var canSpawnObject: Dictionary[StringName, bool] = {}

# biomes this room is a part of. if more than one, this is a transition room
var biomes: Dictionary[Const.BiomeType, bool] = {}
var transitionRoom:
    get: return biomes.keys().size() > 1

# A single AABB that fits all smaller bounding boxes inside it. Useful for very fast checks
var approximateBounds: AABB = AABB()
# AABB ordered array in room-local space of room extents
var bounds: Array[AABB] = []

# Array of room connectors. Every connector is a surface on the face of a bounds AABB
var connectors: Array[RoomConnectorDefinition] = []

# Used to tell dynamic scenes how to spawn. A single scene defining multiple rooms will create 
# multiple room definitions. At instantiation time, that scene creates a specific room based on 
# what's stored here
var dynamicRoomProps: Dictionary[StringName, Variant] = {}

func _init(_roomSceneName: StringName) -> void:
    # a single room scene can be used for multiple room definitions. the relationship is one to many
    # the level manager has a complete dictionary of room scenes it can instantiate. store the described
    # room's key
    roomSceneName = _roomSceneName

func add_bounds_shape(collisionShape: CollisionShape3D) -> void:
    var newBoundingBox = AABB(collisionShape.position - (collisionShape.shape.size / 2.0), collisionShape.shape.size)
    approximateBounds.expand(newBoundingBox)
    bounds.append(newBoundingBox)

func add_connector(connector: RoomConnector):
    var newConnector = RoomConnectorDefinition.new(connector)
    biomes.set(newConnector.biome, true)
    connectors.append(newConnector)
