@tool
extends "res://objects/room_connector/floor/floor_connector.gd"
class_name CeilingConnector

func _init() -> void:
    depthDirection = -1.0

func on_other_connection_entered(body: Area3D):
    var otherConnection = body.get_parent()
    if not otherConnection is FloorConnector: return
    var otherIndex = coplanarConnections.find(otherConnection)
    if otherIndex != -1: return
    coplanarConnections.append(otherConnection)
