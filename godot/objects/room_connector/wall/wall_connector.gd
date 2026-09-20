@tool
extends "res://objects/room_connector/room_connector.gd"
class_name WallConnector

const WallConnectorEditorHelperRes = preload("res://objects/room_connector/wall/wall_connector_editor_helper.gd")
var editorHelper: WallConnectorEditorHelper = null

@export_range(0.5, 30.0, 0.5, "or_greater") var connectionWidth: float = 4.0:
    set(newValue):
        if editorHelper != null: editorHelper.update_connection_width(newValue)
        connectionWidth = newValue
@export_range(0.5, 30.0, 0.5, "or_greater") var connectionHeight: float = 3.5:
    set(newValue):
        if editorHelper != null: editorHelper.update_connection_height(newValue)
        connectionHeight = newValue

@onready var adjacent: Area3D = $Adjacent
@onready var adjacentCollider: CollisionShape3D = $Adjacent/RectCollider

@onready var collider: StaticBody3D = $Collider

var aabb: AABB
var coplanarConnections: Array[WallConnector]

func _ready() -> void:
    if Engine.is_editor_hint():
        editorHelper = WallConnectorEditorHelperRes.new(self)
    else:
        aabb = AABB()
        aabb.position = to_global(adjacentCollider.position - (adjacentCollider.shape.size / 2.0))
        aabb.end = to_global(adjacentCollider.position + (adjacentCollider.shape.size / 2.0))
        aabb = aabb.abs()
        coplanarConnections = []
        adjacent.area_entered.connect(on_other_connection_entered)
        adjacent.area_exited.connect(on_other_connection_exited)
        await get_tree().physics_frame
        await get_tree().physics_frame
        await get_tree().physics_frame
        build_connections()

func on_other_connection_entered(body: Area3D):
    var otherConnection = body.get_parent()
    if not otherConnection is WallConnector: return
    var otherIndex = coplanarConnections.find(otherConnection)
    if otherIndex != -1: return
    var calculatedDot = otherConnection.transform.basis.z.dot(transform.basis.z)
    if abs(calculatedDot) > 0.95:
        coplanarConnections.append(otherConnection)

func on_other_connection_exited(body: Area3D):
    var parentIndex = coplanarConnections.find(body.get_parent())
    if parentIndex != -1:
        coplanarConnections.remove_at(parentIndex)

# Punch hole for every coplanar connection
func build_connections() -> bool:
    # assumes holes never overlap
    var holesInLocalSpace: Array[Rect2] = []
    # shapes work from center, but AABB and Rect2 work from the corner.
    var centerOffset = (adjacentCollider.shape.size / 2.0)
    for nextConnection in coplanarConnections:
        var intersection: AABB = aabb.intersection(nextConnection.aabb)
        # put AABB intersection into local space and offset the center
        var corner1 = to_local(intersection.position) + centerOffset
        var corner2 = to_local(intersection.end) + centerOffset
        # transform into 2d wall coordinates; +z direction of wall
        # Origin from top left of wall. Wrap Y around shape height so this works
        holesInLocalSpace.append(Rect2(
            Vector2(min(corner1.x, corner2.x), adjacentCollider.shape.size.y - max(corner1.y, corner2.y)),
            Vector2(max(corner1.x, corner2.x), adjacentCollider.shape.size.y - min(corner1.y, corner2.y))
        ))
    punch_holes(holesInLocalSpace)
    return coplanarConnections.size() > 0

func punch_holes(allHoles: Array[Rect2]):
    print(allHoles)

func is_orthogonal() -> bool:
    return 100.0 > abs(global_rotation_degrees.y) && abs(global_rotation_degrees.y) > 80.0
