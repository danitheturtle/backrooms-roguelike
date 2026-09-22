@tool
extends "res://objects/room_connector/room_connector.gd"
class_name WallConnector

const WallConnectorEditorHelperRes = preload("res://objects/room_connector/wall/wall_connector_editor_helper.gd")
var editorHelper: WallConnectorEditorHelper = null

@export_range(0.5, 15.0, 0.5, "or_greater") var connectionWidth: float = 4.0:
    set(newValue):
        if editorHelper != null: editorHelper.update_connection_width(newValue)
        connectionWidth = newValue
@export_range(0.5, 15.0, 0.5, "or_greater") var connectionHeight: float = 3.50:
    set(newValue):
        if editorHelper != null: editorHelper.update_connection_height(newValue)
        connectionHeight = newValue
@export_range(0.25,5.0,0.25, "or_greater") var connectionDepth: float = 0.25:
    set(newValue):
        if editorHelper != null: editorHelper.update_connection_depth(newValue)
        connectionDepth = newValue

@export_group('Generate Edges', 'wallFor')
@export var wallForLeftEdge: bool = true
@export var wallForTopEdge: bool = true
@export var wallForRightEdge: bool = true
@export var wallForBottomEdge: bool = true

@onready var staticBody: StaticBody3D = $Collider
@onready var collider: CollisionShape3D = $Collider/RectCollider

@onready var mesh: MeshInstance3D = $Mesh

@onready var adjacent: Area3D = $Adjacent
@onready var adjacentCollider: CollisionShape3D = $Adjacent/RectCollider

var adjacentAABB: AABB
var coplanarConnections: Array[WallConnector]
var surfaceOffsetInNormal: float

func _ready() -> void:
    if Engine.is_editor_hint():
        editorHelper = WallConnectorEditorHelperRes.new(self)
    else:
        adjacentAABB = AABB()
        adjacentAABB.position = to_global(adjacentCollider.position - (adjacentCollider.shape.size / 2.0))
        adjacentAABB.end = to_global(adjacentCollider.position + (adjacentCollider.shape.size / 2.0))
        adjacentAABB = adjacentAABB.abs()
        coplanarConnections = []
        surfaceOffsetInNormal = mesh.position.z
        adjacent.area_entered.connect(on_other_connection_entered)
        adjacent.area_exited.connect(on_other_connection_exited)
        await get_tree().physics_frame
        await get_tree().physics_frame
        # TODO move to level manager
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

# Punch hole for every coplanar connection and store metadata about it
# assumes holes never overlap with 1 voxel (0.5) gap
# returns true if at least one connection was made
func build_connections() -> bool:
    if coplanarConnections.size() == 0: return false
    var holesInLocalSpace: Array[Rect2] = []
    # shapes work from center, but AABB and Rect2 work from the corners
    var centerOffset = Vector3(connectionWidth, connectionHeight, 0.0) / 2.0
    for nextConnection in coplanarConnections:
        var intersection: AABB = adjacentAABB.intersection(nextConnection.adjacentAABB)
        # put AABB intersection into local space and offset the center
        var corner1 = to_local(intersection.position) + centerOffset
        var corner2 = to_local(intersection.end) + centerOffset
        # transform into 2d wall coordinates; +z direction of wall
        # Origin from top left of wall. Wrap Y around shape height so this works
        var wallspaceHolePosition = Vector2(min(corner1.x, corner2.x), connectionHeight - max(corner1.y, corner2.y))
        var wallspaceHoleEnd = Vector2(max(corner1.x, corner2.x), connectionHeight - min(corner1.y, corner2.y))
        holesInLocalSpace.append(Rect2(wallspaceHolePosition,wallspaceHoleEnd - wallspaceHolePosition))
    var localSpace: Rect2 = Rect2(0,0,connectionWidth,connectionHeight)
    # exit early if coplanar surfaces had trouble forming holes
    if holesInLocalSpace.size() == 0: return false
    # exit early if this connection gets removed entirely
    if holesInLocalSpace[0].is_equal_approx(localSpace):
        disable_default_geometry()
        return true
    # holes form a subsurface, generate 2d planes to fill the voids (expensive)
    var surfacesInLocalSpace = generate_surfaces_around_holes(Vector2(connectionWidth,connectionHeight), holesInLocalSpace)
    if surfacesInLocalSpace.size() == 0:
        disable_default_geometry()
        return true
    for nextSurface in surfacesInLocalSpace:
        var centerRelativeToParent: Vector3 = get_relative_center(nextSurface, centerOffset)
        var newCollider: CollisionShape3D = new_collider()
        newCollider.position = centerRelativeToParent - Vector3(0.0,0.0,connectionDepth / 2.0)
        newCollider.shape.size = Vector3(nextSurface.size.x, nextSurface.size.y, connectionDepth)
        var newMesh: MeshInstance3D = new_mesh(centerRelativeToParent, nextSurface.size)
    for nextHole in holesInLocalSpace:
        var holeCenter: Vector3 = get_relative_center(nextHole, centerOffset)
        var halfHoleWidth = nextHole.size.x / 2.0
        var halfHoleHeight = nextHole.size.y / 2.0
        # skip meshes at the edge of the wall
        if wallForLeftEdge || !Utils.equalsf(nextHole.position.x,0.0):
            # build left mesh
            var leftHoleMesh = new_mesh(Vector3(holeCenter.x - halfHoleWidth, holeCenter.y, connectionDepth / 2.0), Vector2(connectionDepth, nextHole.size.y), 0.0, 90.0)
        if wallForTopEdge || !Utils.equalsf(nextHole.position.y,0.0):
            # build top mesh
            var topHoleMesh = new_mesh(Vector3(holeCenter.x, holeCenter.y + halfHoleHeight, connectionDepth / 2.0), Vector2(nextHole.size.x, connectionDepth), 90.0)
        if wallForRightEdge || !Utils.equalsf(nextHole.end.x,connectionWidth):
            # build right mesh
            var rightHoleMesh = new_mesh(Vector3(holeCenter.x + halfHoleWidth, holeCenter.y, connectionDepth / 2.0), Vector2(connectionDepth, nextHole.size.y), 0.0, -90.0)
        if wallForBottomEdge || !Utils.equalsf(nextHole.end.y,connectionHeight):
            # build bottom mesh
            var bottomHoleMesh = new_mesh(Vector3(holeCenter.x, holeCenter.y - halfHoleHeight, connectionDepth / 2.0), Vector2(nextHole.size.x, connectionDepth), -90.0)
    disable_default_geometry()
    return coplanarConnections.size() > 0

func disable_default_geometry():
    if wallForLeftEdge:
        var farLeftMesh = new_mesh(Vector3(connectionWidth/2.0,0.0,connectionDepth/2.0), Vector2(connectionDepth,connectionHeight),0.0,-90.0)
    if wallForTopEdge:
        var farTopMesh = new_mesh(Vector3(0.0,connectionHeight/2.0,connectionDepth/2.0), Vector2(connectionWidth, connectionDepth), 90.0)
    if wallForRightEdge:
        var farRightMesh = new_mesh(Vector3(-connectionWidth/2.0,0.0,connectionDepth/2.0), Vector2(connectionDepth,connectionHeight),0.0,90.0)
    if wallForBottomEdge:
        var farBottomMesh = new_mesh(Vector3(0.0,-connectionHeight/2.0,connectionDepth/2.0), Vector2(connectionWidth, connectionDepth), -90.0)
    collider.process_mode = Node.PROCESS_MODE_DISABLED
    collider.set_deferred("disabled", true)
    collider.hide()
    mesh.process_mode = Node.PROCESS_MODE_DISABLED
    mesh.hide()

func new_mesh(_position: Vector3, _size: Vector2, _rotateXDeg: float = 0.0, _rotateYDeg: float = 0.0) -> MeshInstance3D:
    var newMesh: MeshInstance3D = mesh.duplicate()
    newMesh.mesh = mesh.mesh.duplicate()
    self.add_child(newMesh)
    newMesh.mesh.size = _size
    newMesh.position = _position
    if !Utils.equalsf(0.0,_rotateXDeg): newMesh.rotate_x(deg_to_rad(_rotateXDeg))
    if !Utils.equalsf(0.0,_rotateYDeg): newMesh.rotate_y(deg_to_rad(_rotateYDeg))
    if Engine.is_editor_hint(): newMesh.owner = EditorInterface.get_edited_scene_root()
    return newMesh

func new_collider():
    var newCollider: CollisionShape3D = collider.duplicate()
    newCollider.shape = collider.shape.duplicate()
    staticBody.add_child(newCollider)
    if Engine.is_editor_hint(): newCollider.owner = EditorInterface.get_edited_scene_root()
    return newCollider

func get_relative_center(surfaceRect: Rect2, centerOffset: Vector3):
    var centerLocal = surfaceRect.position + (surfaceRect.size / 2.0)
    return Vector3(centerLocal.x,connectionHeight-centerLocal.y,surfaceOffsetInNormal) - centerOffset
