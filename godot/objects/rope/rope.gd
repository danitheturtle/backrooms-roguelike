class_name Rope
extends Area3D

@export var anchor: RopeAnchor
@export var path: Path3D

var length: float:
    get: return path.curve.get_baked_length()
var lengthVoxels: int:
    get: return roundi(length / Const.VOXEL)

var playerAmmoAtCreation: int = 0

func _ready() -> void:
    # newly created curve has no points
    while path.curve.point_count < 2:
        path.curve.add_point(Vector3.ZERO)
    # a pre-placed rope always has a valid path
    # build segment shapes for every segment on path
    for nextSegmentIndex in path.curve.point_count-1:
        pass

func _physics_process(_delta: float) -> void:
    pass
