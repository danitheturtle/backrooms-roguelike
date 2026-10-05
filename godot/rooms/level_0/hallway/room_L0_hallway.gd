@tool
class_name RoomHallway
extends Room

@export_range(4,32,1, "prefer_slider", "or_greater") var voxelLength: int = 4: set = set_voxel_length

var wallConnectorXPos: WallConnector
var wallConnectorXNeg: WallConnector
var resizableFloor: ResizableFloor
var resizableCeiling: ResizableCeiling
var resizableWallZPos: ResizableWall
var resizableWallZNeg: ResizableWall
var boundsAABB: CollisionShape3D

func grab_refs() -> void:
    super.grab_refs()
    wallConnectorXPos = get_node("Connectors/WallConnectorXPos")
    wallConnectorXNeg = get_node("Connectors/WallConnectorXNeg")
    resizableFloor = get_node("LevelMeshes/ResizableFloor")
    resizableCeiling = get_node("LevelMeshes/ResizableCeiling")
    resizableWallZPos = get_node("LevelMeshes/ResizeableWallZPos")
    resizableWallZNeg = get_node("LevelMeshes/ResizeableWallZNeg")
    boundsAABB = get_node("Bounds/BoundsAABB")

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

func get_dynamics_for_index(index: int) -> Dictionary[StringName, Variant]:
    return {
        &"voxelLength": 4 + ((index*2) * index)
    }

#func shuffle() -> void:
    # TODO spawn lights
