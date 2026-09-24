class_name RoomDefinition

var spawnWeight: float
var onlySpawnAfterNIterations: int
var roomBounds: Array[AABB]
# make sure to include biome data with connections. If a room transitions between one or more biomes, also note that
func _init() -> void:
    pass

func get_voxel_bounds(): #todo
    pass
