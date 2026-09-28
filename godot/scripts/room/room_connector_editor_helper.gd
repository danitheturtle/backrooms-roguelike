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

func update_connector_width(newValue: int, axis: StringName):
    var newWidth: float = float(newValue) * Const.VOXEL
    collider.shape.size[axis] = newWidth
    adjacentCollider.shape.size[axis] = newWidth
    mesh.mesh.size.x = newWidth

func update_connector_height(newValue: int, axis: StringName):
    var newHeight: float = float(newValue) * Const.VOXEL
    collider.shape.size[axis] = newHeight
    adjacentCollider.shape.size[axis] = newHeight
    mesh.mesh.size.y = newHeight

func update_connector_depth(newValue: float, axis: StringName):
    var newDepth: float = float(newValue) * Const.VOXEL
    mesh.position[axis] = newDepth
    collider.shape.size[axis] = abs(newDepth)
    collider.position[axis] = newDepth / 2.0
