@tool
extends Node
class_name WallConnectorEditorHelper

var parent: WallConnector
var adjacentDetector: Area3D
var adjacentCollider: CollisionShape3D
var staticBody: StaticBody3D
var collider: CollisionShape3D
var mesh: MeshInstance3D

func _init(_parent: WallConnector) -> void:
    parent = _parent
    var container: Node = parent.get_parent()
    if container != null:
        if !container.is_editable_instance(parent):
            container.set_editable_instance(parent, true)
    var allChildren := parent.get_children()
    for nextChild in allChildren:
        if nextChild is StaticBody3D:
            staticBody = nextChild
            collider = staticBody.get_child(0)
        elif nextChild is MeshInstance3D:
            mesh = nextChild
        elif nextChild is Area3D:
            adjacentDetector = nextChild
            adjacentCollider = adjacentDetector.get_child(0)

func update_connection_width(newValue: float):
    collider.shape.size.x = newValue
    adjacentCollider.shape.size.x = newValue
    mesh.mesh.size.x = newValue

func update_connection_height(newValue: float):
    collider.shape.size.y = newValue
    adjacentCollider.shape.size.y = newValue
    mesh.mesh.size.y = newValue

func update_connection_depth(newValue: float):
    mesh.position.z = newValue
    collider.shape.size.z = newValue
    collider.position.z = newValue / 2.0
    adjacentCollider.shape.size.z = newValue + 0.25
    adjacentCollider.position.z = (newValue - 0.25) / 2.0
