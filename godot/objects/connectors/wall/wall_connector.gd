@tool
extends "res://scripts/room_connector.gd"
class_name WallConnector

func set_connection_height(newHeight: float) -> void:
    if editorHelper != null: editorHelper.update_connection_height(newHeight, "y")
    connectionHeight = newHeight

func set_connection_depth(newDepth: float) -> void:
    if editorHelper != null: editorHelper.update_connection_depth(newDepth, "z")
    connectionDepth = newDepth

func on_other_connection_entered(body: Area3D):
    var otherConnection = body.get_parent()
    if not otherConnection is WallConnector: return
    var otherIndex = coplanarConnections.find(otherConnection)
    if otherIndex != -1: return
    var calculatedDot = otherConnection.global_basis.z.dot(global_basis.z)
    if calculatedDot < -0.95:
        coplanarConnections.append(otherConnection)

func disable_default_geometry(generateEdges: bool = false):
    if generateEdges:
        if edgeGenWest:
            new_mesh(Vector3(-halfWidth, 0.0, halfDepth), Vector2(connectionDepth, connectionHeight), farEdgeWestMaterial, 0.0, 90.0)
            if edgeGenCollision:
                new_collider(Vector3(-halfWidth - State.QUARTER_VOXEL, 0.0, halfDepth), Vector3(State.HALF_VOXEL,connectionHeight,connectionDepth))
        if edgeGenNorth:
            new_mesh(Vector3(0.0, halfHeight, halfDepth), Vector2(connectionWidth, connectionDepth), farEdgeNorthMaterial, 90.0)
            if edgeGenCollision:
                new_collider(Vector3(0.0, halfHeight + State.QUARTER_VOXEL, halfDepth), Vector3(connectionWidth, State.HALF_VOXEL, connectionDepth))
        if edgeGenEast:
            new_mesh(Vector3(halfWidth, 0.0, halfDepth), Vector2(connectionDepth, connectionHeight), farEdgeEastMaterial, 0.0, -90.0)
            if edgeGenCollision:
                new_collider(Vector3(halfWidth + State.QUARTER_VOXEL, 0.0, halfDepth), Vector3(State.HALF_VOXEL, connectionHeight, connectionDepth))
        if edgeGenSouth:
            new_mesh(Vector3(0.0, -halfHeight, halfDepth), Vector2(connectionWidth, connectionDepth), farEdgeSouthMaterial, -90.0)
            if edgeGenCollision:
                new_collider(Vector3(0.0, -halfHeight - State.QUARTER_VOXEL, halfDepth), Vector3(connectionWidth, State.HALF_VOXEL, connectionDepth))
    # this disables the mesh we just cloned, call it after we're done
    super.disable_default_geometry(generateEdges)

func get_center_offset() -> Vector3:
    return Vector3(connectionWidth, connectionHeight, 0.0) / 2.0

func get_local_hole_position(corner1: Vector3, corner2: Vector3) -> Vector2:
    return Vector2(min(corner1.x, corner2.x), connectionHeight - max(corner1.y, corner2.y))

func get_local_hole_end(corner1: Vector3, corner2: Vector3) -> Vector2:
    return Vector2(max(corner1.x, corner2.x), connectionHeight - min(corner1.y, corner2.y))

func get_center_relative_to_parent(surfaceRect: Rect2, centerOffset: Vector3) -> Vector3:
    var centerLocal = surfaceRect.position + (surfaceRect.size / 2.0)
    return Vector3(centerLocal.x,connectionHeight-centerLocal.y,connectionDepth) - centerOffset

func build_geometry_for_surface(surface: Rect2, centerOffset: Vector3) -> void:
    var centerRelativeToParent: Vector3 = get_center_relative_to_parent(surface, centerOffset)
    new_collider(centerRelativeToParent - Vector3(0.0,0.0,halfDepth), Vector3(surface.size.x, surface.size.y, connectionDepth))
    new_mesh(centerRelativeToParent, surface.size)

func build_geometry_for_hole(hole: Rect2, centerOffset: Vector3) -> void:
    var holeCenter: Vector3 = get_center_relative_to_parent(hole, centerOffset)
    var halfHoleWidth = hole.size.x / 2.0
    var halfHoleHeight = hole.size.y / 2.0
    # skip meshes at the edge of the wall
    var atWestEdge = Utils.equalsf(hole.position.x,0.0)
    if edgeGenWest || !atWestEdge:
        new_mesh(Vector3(holeCenter.x - halfHoleWidth, holeCenter.y, halfDepth),
                 Vector2(connectionDepth, hole.size.y),
                 farEdgeWestMaterial if atWestEdge else innerEdgeWestMaterial,
                 0.0, 90.0)
        if edgeGenCollision:
            new_collider(Vector3(holeCenter.x - halfHoleWidth - State.QUARTER_VOXEL, holeCenter.y, halfDepth),
                         Vector3(State.HALF_VOXEL, hole.size.y, connectionDepth))
    var atNorthEdge = Utils.equalsf(hole.position.y,0.0)
    if edgeGenNorth || !atNorthEdge:
        new_mesh(Vector3(holeCenter.x, holeCenter.y + halfHoleHeight, halfDepth),
                 Vector2(hole.size.x, connectionDepth),
                 farEdgeNorthMaterial if atNorthEdge else innerEdgeNorthMaterial,
                 90.0)
        if edgeGenCollision:
            new_collider(Vector3(holeCenter.x, holeCenter.y + halfHoleHeight + State.QUARTER_VOXEL, halfDepth),
                         Vector3(hole.size.x, State.HALF_VOXEL, connectionDepth))
    var atEastEdge = Utils.equalsf(hole.end.x,connectionWidth)
    if edgeGenEast || !atEastEdge:
        new_mesh(Vector3(holeCenter.x + halfHoleWidth, holeCenter.y, halfDepth),
                 Vector2(connectionDepth, hole.size.y),
                 farEdgeEastMaterial if atEastEdge else innerEdgeEastMaterial,
                 0.0, -90.0)
        if edgeGenCollision:
            new_collider(Vector3(holeCenter.x + halfHoleWidth + State.QUARTER_VOXEL, holeCenter.y, halfDepth),
                         Vector3(State.HALF_VOXEL, hole.size.y, connectionDepth))
    var atSouthEdge = Utils.equalsf(hole.end.y,connectionHeight)
    if edgeGenSouth || !atSouthEdge:
        new_mesh(Vector3(holeCenter.x, holeCenter.y - halfHoleHeight, halfDepth),
                 Vector2(hole.size.x, connectionDepth),
                 farEdgeSouthMaterial if atSouthEdge else innerEdgeSouthMaterial,
                 -90.0)
        if edgeGenCollision:
            new_collider(Vector3(holeCenter.x, holeCenter.y - halfHoleHeight - State.QUARTER_VOXEL, halfDepth),
                         Vector3(hole.size.x, State.HALF_VOXEL, connectionDepth))
