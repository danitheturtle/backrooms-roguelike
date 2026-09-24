@tool
extends "res://objects/room_connector/room_connector.gd"
class_name FloorConnector

var depthDirection: float = 1.0
var halfDepth: float:
    get: return depthDirection * connectionDepth / 2.0

func set_connection_height(newHeight: float) -> void:
    if editorHelper != null: editorHelper.update_connection_height(newHeight, "z")
    connectionHeight = newHeight

func set_connection_depth(newDepth: float) -> void:
    if editorHelper != null: editorHelper.update_connection_depth(depthDirection * newDepth, "y")
    connectionDepth = newDepth

func on_other_connection_entered(body: Area3D):
    var otherConnection = body.get_parent()
    if not otherConnection is CeilingConnector: return
    var otherIndex = coplanarConnections.find(otherConnection)
    if otherIndex != -1: return
    coplanarConnections.append(otherConnection)

func disable_default_geometry(generateEdges: bool = false):
    if generateEdges:
        if wallForWestEdge:
            new_mesh(Vector3(-connectionWidth / 2.0, halfDepth, 0.0),
                     Vector2(connectionDepth, connectionHeight),
                     innerEdgeWestMaterial,
                     0.0, 0.0, -90.0 * depthDirection)
        if wallForNorthEdge:
            new_mesh(Vector3(0.0, halfDepth, connectionHeight / 2.0),
                     Vector2(connectionWidth, connectionDepth),
                     innerEdgeNorthMaterial,
                     -90.0 * depthDirection)
        if wallForEastEdge:
            new_mesh(Vector3(connectionWidth / 2.0, halfDepth, 0.0),
                     Vector2(connectionDepth,connectionHeight),
                     innerEdgeEastMaterial,
                     0.0, 0.0, 90.0 * depthDirection)
        if wallForSouthEdge:
            new_mesh(Vector3(0.0, halfDepth, -connectionHeight / 2.0),
                     Vector2(connectionWidth, connectionDepth),
                     innerEdgeSouthMaterial,
                     90.0 * depthDirection)
    # this disables the mesh we just cloned, call it after we're done
    super.disable_default_geometry()

func get_center_offset() -> Vector3:
    return Vector3(connectionWidth, 0.0, connectionHeight) / 2.0

func get_local_hole_position(corner1: Vector3, corner2: Vector3) -> Vector2:
    return Vector2(min(corner1.x, corner2.x), connectionHeight - max(corner1.z, corner2.z))

func get_local_hole_end(corner1: Vector3, corner2: Vector3) -> Vector2:
    return Vector2(max(corner1.x, corner2.x), connectionHeight - min(corner1.z, corner2.z))

func get_center_relative_to_parent(surfaceRect: Rect2, centerOffset: Vector3) -> Vector3:
    var centerLocal = surfaceRect.position + (surfaceRect.size / 2.0)
    return Vector3(centerLocal.x, depthDirection * connectionDepth, connectionHeight - centerLocal.y) - centerOffset

func build_geometry_for_surface(surface: Rect2, centerOffset: Vector3) -> void:
    var centerRelativeToParent: Vector3 = get_center_relative_to_parent(surface, centerOffset)
    new_collider(centerRelativeToParent - Vector3(0.0, halfDepth, 0.0), Vector3(surface.size.x, connectionDepth, surface.size.y))
    new_mesh(centerRelativeToParent, surface.size)

func build_geometry_for_hole(hole: Rect2, centerOffset: Vector3) -> void:
    var holeCenter: Vector3 = get_center_relative_to_parent(hole, centerOffset)
    var halfHoleWidth = hole.size.x / 2.0
    var halfHoleHeight = hole.size.y / 2.0
    # skip meshes at the edge of the wall
    if wallForWestEdge || !Utils.equalsf(hole.position.x, 0.0):
        new_mesh(Vector3(holeCenter.x - halfHoleWidth, halfDepth, holeCenter.z),
                 Vector2(connectionDepth, hole.size.y),
                 innerEdgeWestMaterial,
                 0.0, 0.0, -90.0 * depthDirection)
    if wallForNorthEdge || !Utils.equalsf(hole.position.y, 0.0):
        new_mesh(Vector3(holeCenter.x, halfDepth, holeCenter.z - halfHoleHeight),
                 Vector2(hole.size.x, connectionDepth),
                 innerEdgeNorthMaterial,
                 90.0 * depthDirection)
    if wallForEastEdge || !Utils.equalsf(hole.end.x, connectionWidth):
        new_mesh(Vector3(holeCenter.x + halfHoleWidth, halfDepth, holeCenter.z),
                 Vector2(connectionDepth, hole.size.y),
                 innerEdgeEastMaterial,
                 0.0, 0.0, 90.0 * depthDirection)
    if wallForSouthEdge || !Utils.equalsf(hole.end.y, connectionHeight):
        new_mesh(Vector3(holeCenter.x, halfDepth, holeCenter.z + halfHoleHeight),
                 Vector2(hole.size.x, connectionDepth),
                 innerEdgeSouthMaterial,
                 -90.0*depthDirection)
