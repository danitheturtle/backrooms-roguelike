@tool
extends "res://objects/room_connector/room_connector.gd"
class_name FloorConnector

var depthDirection: float = 1.0

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
        if edgeGenWest:
            new_mesh(Vector3(-halfWidth, halfDepth * depthDirection, 0.0),
                     Vector2(connectionDepth, connectionHeight),
                     farEdgeWestMaterial,
                     0.0, 0.0, -90.0 * depthDirection)
            if edgeGenCollision:
                new_collider(Vector3(-halfWidth - State.QUARTER_VOXEL, halfDepth * depthDirection, 0.0),
                             Vector3(State.HALF_VOXEL, connectionDepth, connectionHeight))
        if edgeGenNorth:
            new_mesh(Vector3(0.0, halfDepth * depthDirection, halfHeight),
                     Vector2(connectionWidth, connectionDepth),
                     farEdgeNorthMaterial,
                     -90.0 * depthDirection)
            if edgeGenCollision:
                new_collider(Vector3(0.0, halfDepth * depthDirection, halfHeight + State.QUARTER_VOXEL),
                             Vector3(connectionWidth, connectionDepth, State.HALF_VOXEL))
        if edgeGenEast:
            new_mesh(Vector3(halfWidth, halfDepth * depthDirection, 0.0),
                     Vector2(connectionDepth, connectionHeight),
                     farEdgeEastMaterial,
                     0.0, 0.0, 90.0 * depthDirection)
            if edgeGenCollision:
                new_collider(Vector3(halfWidth + State.QUARTER_VOXEL, halfDepth * depthDirection, 0.0),
                             Vector3(State.HALF_VOXEL, connectionDepth, connectionHeight))
        if edgeGenSouth:
            new_mesh(Vector3(0.0, halfDepth * depthDirection, -halfHeight),
                     Vector2(connectionWidth, connectionDepth),
                     farEdgeSouthMaterial,
                     90.0 * depthDirection)
            if edgeGenCollision:
                new_collider(Vector3(0.0, halfDepth * depthDirection, -halfHeight - State.QUARTER_VOXEL),
                             Vector3(connectionWidth, connectionDepth, State.HALF_VOXEL))
    # this disables the mesh we just cloned, call it after we're done
    super.disable_default_geometry()

func get_center_offset() -> Vector3:
    return Vector3(connectionWidth, 0.0, connectionHeight) / 2.0

func get_local_hole_position(corner1: Vector3, corner2: Vector3) -> Vector2:
    return Vector2(min(corner1.x, corner2.x), min(corner1.z, corner2.z))

func get_local_hole_end(corner1: Vector3, corner2: Vector3) -> Vector2:
    return Vector2(max(corner1.x, corner2.x), max(corner1.z, corner2.z))

func get_center_relative_to_parent(surfaceRect: Rect2, centerOffset: Vector3) -> Vector3:
    var centerLocal = surfaceRect.position + (surfaceRect.size / 2.0)
    return Vector3(centerLocal.x, depthDirection * connectionDepth, centerLocal.y) - centerOffset

func build_geometry_for_surface(surface: Rect2, centerOffset: Vector3) -> void:
    var centerRelativeToParent: Vector3 = get_center_relative_to_parent(surface, centerOffset)
    new_collider(centerRelativeToParent - Vector3(0.0, halfDepth * depthDirection, 0.0), Vector3(surface.size.x, connectionDepth, surface.size.y))
    new_mesh(centerRelativeToParent, surface.size)

func build_geometry_for_hole(hole: Rect2, centerOffset: Vector3) -> void:
    var holeCenter: Vector3 = get_center_relative_to_parent(hole, centerOffset)
    var halfHoleWidth = hole.size.x / 2.0
    var halfHoleHeight = hole.size.y / 2.0
    var atWestEdge = Utils.equalsf(hole.position.x, 0.0)
    if edgeGenWest || !atWestEdge:
        new_mesh(Vector3(holeCenter.x - halfHoleWidth, halfDepth * depthDirection, holeCenter.z),
                 Vector2(connectionDepth, hole.size.y),
                 farEdgeWestMaterial if atWestEdge else innerEdgeWestMaterial,
                 0.0, 0.0, -90.0 * depthDirection)
        if edgeGenCollision:
            new_collider(Vector3(holeCenter.x - halfHoleWidth - State.QUARTER_VOXEL, halfDepth * depthDirection, holeCenter.z),
                         Vector3(State.HALF_VOXEL, connectionDepth, hole.size.y))
    var atNorthEdge = Utils.equalsf(hole.position.y, 0.0)
    if edgeGenNorth || !atNorthEdge:
        new_mesh(Vector3(holeCenter.x, halfDepth * depthDirection, holeCenter.z - halfHoleHeight),
                 Vector2(hole.size.x, connectionDepth),
                 farEdgeNorthMaterial if atNorthEdge else innerEdgeNorthMaterial,
                 90.0 * depthDirection)
        if edgeGenCollision:
            new_collider(Vector3(holeCenter.x, halfDepth * depthDirection, holeCenter.z - halfHoleHeight - State.QUARTER_VOXEL),
                         Vector3(hole.size.x, connectionDepth, State.HALF_VOXEL))
    var atEastEdge = Utils.equalsf(hole.end.x, connectionWidth)
    if edgeGenEast || !atEastEdge:
        new_mesh(Vector3(holeCenter.x + halfHoleWidth, halfDepth * depthDirection, holeCenter.z),
                 Vector2(connectionDepth, hole.size.y),
                 farEdgeEastMaterial if atEastEdge else innerEdgeEastMaterial,
                 0.0, 0.0, 90.0 * depthDirection)
        if edgeGenCollision:
            new_collider(Vector3(holeCenter.x + halfHoleWidth + State.QUARTER_VOXEL, halfDepth * depthDirection, holeCenter.z),
                         Vector3(State.HALF_VOXEL, connectionDepth, hole.size.y))
    var atSouthEdge = Utils.equalsf(hole.end.y, connectionHeight)
    if edgeGenSouth || !atSouthEdge:
        new_mesh(Vector3(holeCenter.x, halfDepth * depthDirection, holeCenter.z + halfHoleHeight),
                 Vector2(hole.size.x, connectionDepth),
                 farEdgeSouthMaterial if atSouthEdge else innerEdgeSouthMaterial,
                 -90.0*depthDirection)
        if edgeGenCollision:
            new_collider(Vector3(holeCenter.x, halfDepth * depthDirection, holeCenter.z + halfHoleHeight + State.QUARTER_VOXEL),
                         Vector3(hole.size.x, connectionDepth, State.HALF_VOXEL))
