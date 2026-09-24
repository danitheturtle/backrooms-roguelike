@tool
extends Node
class_name RoomConnectorEditorHelper

var parent: RoomConnector
var adjacentDetector: Area3D
var adjacentCollider: CollisionShape3D
var staticBody: StaticBody3D
var collider: CollisionShape3D
var mesh: MeshInstance3D

func _init(_parent: RoomConnector) -> void:
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

func update_connection_width(newValue: float, axis: String):
    collider.shape.size[axis] = newValue
    adjacentCollider.shape.size[axis] = newValue
    mesh.mesh.size.x = newValue

func update_connection_height(newValue: float, axis: String):
    collider.shape.size[axis] = newValue
    adjacentCollider.shape.size[axis] = newValue
    mesh.mesh.size.y = newValue

func update_connection_depth(newValue: float, axis: String):
    mesh.position[axis] = newValue
    collider.shape.size[axis] = abs(newValue)
    collider.position[axis] = newValue / 2.0
    adjacentCollider.shape.size[axis] = abs(newValue) + 0.25
    adjacentCollider.position[axis] = ((newValue - 0.25) if newValue > 0.0 else (newValue + 0.25)) / 2.0
