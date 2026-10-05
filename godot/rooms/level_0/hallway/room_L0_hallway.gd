@tool
class_name RoomHallway
extends Room

@export_range(4,32,1, "prefer_slider", "or_greater") var voxelLength: int = 4: set = set_voxel_length

@onready var wallConnectorXPos: WallConnector = $Connectors/WallConnectorXPos
@onready var wallConnectorXNeg: WallConnector = $Connectors/WallConnectorXNeg
@onready var resizableFloor: ResizableFloor = $LevelMeshes/ResizableFloor
@onready var resizableCeiling: ResizableCeiling = $LevelMeshes/ResizableCeiling
@onready var resizableWallZPos: ResizableWall = $LevelMeshes/ResizeableWallZPos
@onready var resizableWallZNeg: ResizableWall = $LevelMeshes/ResizeableWallZNeg
@onready var boundsAABB: CollisionShape3D = $Bounds/BoundsAABB

func set_voxel_length(val: int) -> void:
    voxelLength = val
    if !is_instance_valid(resizableFloor): return
    resizableFloor.voxelWidth = val
    resizableCeiling.voxelWidth = val
    resizableWallZPos.voxelWidth = val
    resizableWallZNeg.voxelWidth = val
    var globalLength = float(val) * Const.VOXEL
    boundsAABB.shape.size.x = globalLength
    wallConnectorXPos.transform.origin.x = globalLength / 2.0
    wallConnectorXNeg.transform.origin.x = -globalLength / 2.0
