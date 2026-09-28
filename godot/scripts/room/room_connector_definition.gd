class_name RoomConnectorDefinition

var name: StringName
var subType: Const.RoomConnectorSubType
var biome: Const.BiomeType
var position: Vector3
var depth: float
var distFromFloor: float
var bordersCeiling: bool
var normal: Vector3
var size: Vector2
var cornerMin: Vector3
var cornerMax: Vector3

var aabb: AABB #this is for debug testing and will go away

func _init(connector: RoomConnector):
    # copied 1-1
    name = connector.get_name()
    subType = connector.metaSubType
    biome = connector.metaBiome
    position = connector.position
    depth = connector.fullDepth
    distFromFloor = connector.voxelDistanceToFloor * Const.VOXEL
    bordersCeiling = connector.voxelBordersCeiling
    # translate to room-local space from connector-local space
    var shapeSize = connector.adjacentCollider.shape.size
    var localCornerMin: Vector3
    var localCornerMax: Vector3
    if connector is WallConnector:
        normal = -connector.global_basis.z
        size = Vector2(shapeSize.x, shapeSize.y)
        localCornerMin = -0.5 * Vector3(shapeSize.x, shapeSize.y, 0.0)
        localCornerMax = 0.5 * Vector3(shapeSize.x, shapeSize.y, 0.0)
    else:
        normal = Vector3.UP if connector is CeilingConnector else Vector3.DOWN
        size = Vector2(shapeSize.x, shapeSize.z)
        localCornerMin = -0.5 * Vector3(shapeSize.x, 0.0, shapeSize.z)
        localCornerMax = 0.5 * Vector3(shapeSize.x, 0.0, shapeSize.z)
    cornerMin = position + connector.basis * localCornerMin
    cornerMax = position + connector.basis * localCornerMax
