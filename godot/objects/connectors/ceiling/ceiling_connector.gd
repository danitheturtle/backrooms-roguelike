@tool
extends "res://objects/connectors/floor/floor_connector.gd"
class_name CeilingConnector

func _init() -> void:
    depthDirection = -1.0

func on_other_connector_entered(body: Area3D):
    var otherConnector = body.get_parent()
    if not otherConnector is FloorConnector: return
    var otherIndex = coplanarConnectors.find(otherConnector)
    if otherIndex != -1: return
    coplanarConnectors.append(otherConnector)
