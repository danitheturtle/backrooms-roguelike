extends RigidBody3D
class_name Holdable

var HOVER_OVER_OBJECT_MATERIAL = preload("res://assets/materials/HoverOverObject/HoverOverObject.tres")

@export var heldDistance = 2.0
@export var heldCollisionRadius = 0.5

@onready var meshInstance = Utils.get_child_of_type(self, MeshInstance3D)

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

func apply_hover_material():
    for nextMaterial in Utils.get_materials_on_mesh(meshInstance):
        HOVER_OVER_OBJECT_MATERIAL.next_pass = nextMaterial
        meshInstance.set_surface_override_material(0, HOVER_OVER_OBJECT_MATERIAL)

func clear_hover_material():
    if meshInstance == null: return
    for surfaceIndex in meshInstance.mesh.get_surface_count():
        var surfaceMaterial = meshInstance.get_surface_override_material(surfaceIndex)
        if surfaceMaterial == HOVER_OVER_OBJECT_MATERIAL:
            meshInstance.set_surface_override_material(surfaceIndex, null)
