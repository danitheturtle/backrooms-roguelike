extends RigidBody3D
class_name Holdable

@export var heldDistance = 2.0
@export var heldCollisionRadius = 0.5

var grabOrigin = Vector3(0.0,0.0,0.0)

func _ready() -> void:
    var grabOriginNode = get_node_or_null("GrabOrigin")
    if (grabOriginNode != null):
        grabOrigin = grabOriginNode.global_position

func on_hold():
    # move to held layer to avoid collision with player and wierd skyrim-style bullshit
    collision_layer = 0b00000000000000100000

func on_drop():
    collision_layer = 0b00000000000000000001

func on_rotate_start():
    pass

func on_rotate_stop():
    pass
