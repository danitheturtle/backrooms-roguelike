class_name Rope
extends Area3D

@export var anchor: RopeAnchor
@export var path: Path3D

func _ready() -> void:
    # a pre-placed rope always has a valid path
    # build segment shapes for every segment on path
    for nextSegmentIndex in path.curve.point_count-1:
        pass

func _physics_process(_delta: float) -> void:
    pass
