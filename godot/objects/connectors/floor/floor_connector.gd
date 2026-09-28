@tool
extends "res://scripts/room/room_connector.gd"
class_name FloorConnector

var depthDirection: float = 1.0

func set_connector_height(newHeight: int) -> void:
    if editorHelper != null: editorHelper.update_connector_height(newHeight, "z")
    voxelHeight = newHeight

func set_connector_depth(newDepth: float) -> void:
    if editorHelper != null: editorHelper.update_connector_depth(depthDirection * newDepth, "y")
    voxelDepth = newDepth

func on_other_connector_entered(body: Area3D):
    var otherConnector = body.get_parent()
    if not otherConnector is CeilingConnector: return
    var otherIndex = coplanarConnectors.find(otherConnector)
    if otherIndex != -1: return
    coplanarConnectors.append(otherConnector)

func disable_default_geometry(generateEdges: bool = false):
    if generateEdges:
        if edgeGenWest:
            new_mesh(Vector3(-halfWidth, halfDepth * depthDirection, 0.0),
                     Vector2(globalDepth, globalHeight),
                     farEdgeWestMaterial,
                     0.0, 0.0, -90.0 * depthDirection)
            if edgeGenCollision:
                new_collider(Vector3(-halfWidth - Const.QUARTER_VOXEL, halfDepth * depthDirection, 0.0),
                             Vector3(Const.HALF_VOXEL, globalDepth, globalHeight))
        if edgeGenNorth:
            new_mesh(Vector3(0.0, halfDepth * depthDirection, halfHeight),
                     Vector2(globalWidth, globalDepth),
                     farEdgeNorthMaterial,
                     -90.0 * depthDirection)
            if edgeGenCollision:
                new_collider(Vector3(0.0, halfDepth * depthDirection, halfHeight + Const.QUARTER_VOXEL),
                             Vector3(globalWidth, globalDepth, Const.HALF_VOXEL))
        if edgeGenEast:
            new_mesh(Vector3(halfWidth, halfDepth * depthDirection, 0.0),
                     Vector2(globalDepth, globalHeight),
                     farEdgeEastMaterial,
                     0.0, 0.0, 90.0 * depthDirection)
            if edgeGenCollision:
                new_collider(Vector3(halfWidth + Const.QUARTER_VOXEL, halfDepth * depthDirection, 0.0),
                             Vector3(Const.HALF_VOXEL, globalDepth, globalHeight))
        if edgeGenSouth:
            new_mesh(Vector3(0.0, halfDepth * depthDirection, -halfHeight),
                     Vector2(globalWidth, globalDepth),
                     farEdgeSouthMaterial,
                     90.0 * depthDirection)
            if edgeGenCollision:
                new_collider(Vector3(0.0, halfDepth * depthDirection, -halfHeight - Const.QUARTER_VOXEL),
                             Vector3(globalWidth, globalDepth, Const.HALF_VOXEL))
    # this disables the mesh we just cloned, call it after we're done
    super.disable_default_geometry()

func get_center_offset() -> Vector3:
    return Vector3(globalWidth, 0.0, globalHeight) / 2.0

func get_local_hole_position(corner1: Vector3, corner2: Vector3) -> Vector2:
    return Vector2(min(corner1.x, corner2.x), min(corner1.z, corner2.z))

func get_local_hole_end(corner1: Vector3, corner2: Vector3) -> Vector2:
    return Vector2(max(corner1.x, corner2.x), max(corner1.z, corner2.z))

func get_center_relative_to_parent(surfaceRect: Rect2, centerOffset: Vector3) -> Vector3:
    var centerLocal = surfaceRect.position + (surfaceRect.size / 2.0)
    return Vector3(centerLocal.x, depthDirection * globalDepth, centerLocal.y) - centerOffset

func build_geometry_for_surface(surface: Rect2, centerOffset: Vector3) -> void:
    var centerRelativeToParent: Vector3 = get_center_relative_to_parent(surface, centerOffset)
    new_collider(centerRelativeToParent - Vector3(0.0, halfDepth * depthDirection, 0.0), Vector3(surface.size.x, globalDepth, surface.size.y))
    new_mesh(centerRelativeToParent, surface.size)

func build_geometry_for_hole(hole: Rect2, centerOffset: Vector3) -> void:
    var holeCenter: Vector3 = get_center_relative_to_parent(hole, centerOffset)
    var halfHoleWidth = hole.size.x / 2.0
    var halfHoleHeight = hole.size.y / 2.0
    var atWestEdge = Utils.equalsf(hole.position.x, 0.0)
    if edgeGenWest || !atWestEdge:
        new_mesh(Vector3(holeCenter.x - halfHoleWidth, halfDepth * depthDirection, holeCenter.z),
                 Vector2(globalDepth, hole.size.y),
                 farEdgeWestMaterial if atWestEdge else innerEdgeWestMaterial,
                 0.0, 0.0, -90.0 * depthDirection)
        if edgeGenCollision:
            new_collider(Vector3(holeCenter.x - halfHoleWidth - Const.QUARTER_VOXEL, halfDepth * depthDirection, holeCenter.z),
                         Vector3(Const.HALF_VOXEL, globalDepth, hole.size.y))
    var atNorthEdge = Utils.equalsf(hole.position.y, 0.0)
    if edgeGenNorth || !atNorthEdge:
        new_mesh(Vector3(holeCenter.x, halfDepth * depthDirection, holeCenter.z - halfHoleHeight),
                 Vector2(hole.size.x, globalDepth),
                 farEdgeNorthMaterial if atNorthEdge else innerEdgeNorthMaterial,
                 90.0 * depthDirection)
        if edgeGenCollision:
            new_collider(Vector3(holeCenter.x, halfDepth * depthDirection, holeCenter.z - halfHoleHeight - Const.QUARTER_VOXEL),
                         Vector3(hole.size.x, globalDepth, Const.HALF_VOXEL))
    var atEastEdge = Utils.equalsf(hole.end.x, globalWidth)
    if edgeGenEast || !atEastEdge:
        new_mesh(Vector3(holeCenter.x + halfHoleWidth, halfDepth * depthDirection, holeCenter.z),
                 Vector2(globalDepth, hole.size.y),
                 farEdgeEastMaterial if atEastEdge else innerEdgeEastMaterial,
                 0.0, 0.0, 90.0 * depthDirection)
        if edgeGenCollision:
            new_collider(Vector3(holeCenter.x + halfHoleWidth + Const.QUARTER_VOXEL, halfDepth * depthDirection, holeCenter.z),
                         Vector3(Const.HALF_VOXEL, globalDepth, hole.size.y))
    var atSouthEdge = Utils.equalsf(hole.end.y, globalHeight)
    if edgeGenSouth || !atSouthEdge:
        new_mesh(Vector3(holeCenter.x, halfDepth * depthDirection, holeCenter.z + halfHoleHeight),
                 Vector2(hole.size.x, globalDepth),
                 farEdgeSouthMaterial if atSouthEdge else innerEdgeSouthMaterial,
                 -90.0*depthDirection)
        if edgeGenCollision:
            new_collider(Vector3(holeCenter.x, halfDepth * depthDirection, holeCenter.z + halfHoleHeight + Const.QUARTER_VOXEL),
                         Vector3(hole.size.x, globalDepth, Const.HALF_VOXEL))
