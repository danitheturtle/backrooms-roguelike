class_name RoomDefinition

# Everything is defined relative to the room's origin.

class Connection:
    var corner1: Vector3
    var corner2: Vector3
    var normal: Vector3
    func _init(connector: RoomConnector):
        # WIP, this isn't right. its in global coords and should not be? I think?
        corner1 = connector.adjacentAABB.position
        corner2 = connector.adjacentAABB.end
        if connector is WallConnector:
            normal = -connector.global_basis.z
        elif connector is CeilingConnector:
            normal = Vector3.UP
        elif connector is FloorConnector:
            normal = Vector3.DOWN

var spawnWeight: float
var onlySpawnAfterNIterations: int
var bounds: Array[AABB]
var connections: Array[Connection]

# make sure to include biome data with connections. If a room transitions between one or more biomes, also note that
func _init() -> void:
    pass

func get_voxel_bounds():
    # TODO
    pass
