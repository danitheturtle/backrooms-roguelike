class_name RoomDefinition
extends Resource

# Room-local space is defined relative to the room's origin which is always Vector3.ZERO
# External transformations should only be applied to the room and they will automatically cascade
# all values here will remain in room-local space which makes it easy to calculate
# global coords for any of the values in this data structure

# Called by level generator to get a levelgen output object
func get_generated_instance() -> GeneratedRoom:
    var newGeneratedRoom = GeneratedRoom.new(self)
    for nextConnectorName: StringName in connectors.keys():
        var newGeneratedConnector = connectors[nextConnectorName].get_generated_instance(newGeneratedRoom.roomInstanceId)
        newGeneratedRoom.generatedConnectors[nextConnectorName] = newGeneratedConnector
    return newGeneratedRoom

###
### ROOM EDITOR
###
# unique name for room scene
@export var sceneName: StringName = ""
# room placed manually and is not part of level generation
@export var excludeFromGeneration: bool = false
# controls room rarity. range and representative values TBD
@export var spawnWeight: float = 1.0
# controls how late-game the room is. Mainly used for exits. Range and representative values TBD
@export var minSpawnIteration: int = 0
# before room spawns it has custom sub-generation to run
@export var hasSubRandomization: bool = false
# set of puzzle objects the level generator can force-spawn in this room to prevent puzzle lockouts
# TODO add to bake system once object spawners can inform pipeline
@export var canSpawnGameplayProp: Dictionary[Const.GameplayPropType, bool] = {}

###
### BAKED
###
# room scene path for instantiation
var scenePath: String = ""
# this definition's index in the room's array of definitions
var indexInScene: int = 0
# biomes this room is a part of. if more than one, this is a transition room
var biomes: Dictionary[Const.BiomeType, bool] = {}
var isTransitionRoom:
    get: return biomes.keys().size() > 1
# A single AABB that fits all smaller bounding boxes inside it. Useful for very fast checks
var approximateBounds: AABB = AABB(Vector3.ZERO,Vector3.ZERO)
# AABB ordered array in room-local space of room extents. Garunteed to be on voxel grid
var bounds: Array[AABB] = []
# Room connectors. Every connector is a surface on the face of a bounds AABB
@export var connectors: Dictionary[StringName, ConnectorDefinition] = {}
# Used to tell dynamic scenes how to spawn. A single scene defining multiple rooms will create 
# multiple room definitions. At instantiation time, that scene creates a specific room based on 
# what's stored here
var dynamicRoomData: Dictionary[StringName, Variant] = {}

# called by room level editor
func bake(room: Room) -> RoomDefinition:
    scenePath = room.owner.scene_file_path
    ## connector
    #name = connector.get_name()
    #subType = connector.metaSubType
    #biome = connector.metaBiome
    #position = connector.position
    #depth = connector.globalDepth
    #distFromFloor = connector.voxelDistanceToFloor * Const.VOXEL
    #bordersCeiling = connector.voxelBordersCeiling
    ## translate to room-local space from connector-local space
    #var shapeSize = connector.adjacentCollider.shape.size
    #var localCornerMin: Vector3
    #var localCornerMax: Vector3
    #if connector is WallConnector:
        #normal = -connector.global_basis.z
        #size = Vector2(shapeSize.x, shapeSize.y)
        #localCornerMin = -0.5 * Vector3(shapeSize.x, shapeSize.y, 0.0)
        #localCornerMax = 0.5 * Vector3(shapeSize.x, shapeSize.y, 0.0)
    #else:
        #normal = Vector3.UP if connector is CeilingConnector else Vector3.DOWN
        #size = Vector2(shapeSize.x, shapeSize.z)
        #localCornerMin = -0.5 * Vector3(shapeSize.x, 0.0, shapeSize.z)
        #localCornerMax = 0.5 * Vector3(shapeSize.x, 0.0, shapeSize.z)
    #cornerMin = position + connector.basis * localCornerMin
    #cornerMax = position + connector.basis * localCornerMax
    return self

#func add_bounds_shape(collisionShape: CollisionShape3D) -> void:
    #var newBoundingBox = AABB(collisionShape.position - (collisionShape.shape.size / 2.0), collisionShape.shape.size)
    #approximateBounds.expand(newBoundingBox)
    #bounds.append(newBoundingBox)

#func add_connector(connector: RoomConnector):
    #biomes.set(connector.definition.biome, true)
    #connectors.set(connector.definition.name, connector.definition)
