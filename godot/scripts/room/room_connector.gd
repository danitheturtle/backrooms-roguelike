@tool
@abstract
extends Node3D
class_name RoomConnector

const Wallpaper01WorldMaterial = preload("res://assets/materials/Wallpaper01/Wallpaper01_world.tres")
const DropCeilingRectangle01WorldMaterial = preload("res://assets/materials/DropCeilingRectangle01/DropCeilingRectangle01_world.tres")
const Carpet01WorldMaterial = preload("res://assets/materials/Carpet01/Carpet01_world.tres")

var editorHelper: ConnectorEditorHelper = null

###
### Editor Adjustable
###
@export_group('Voxel Sizing', 'voxel')
# basic bounds in voxels
@export_range(1, 32, 1, "or_greater", "prefer_slider") var voxelWidth: int = 6: set = set_connector_width
func set_connector_width(newWidth: int) -> void: #only one that's the same for all connector
    if editorHelper != null: editorHelper.update_connector_width(newWidth, "x")
    voxelWidth = newWidth
@export_range(1, 32, 1, "or_greater", "prefer_slider") var voxelHeight: int = 6: set = set_connector_height
@abstract func set_connector_height(newHeight: int) -> void
@export_range(0.5,8.0,0.5, "or_greater", "prefer_slider") var voxelDepth: float = 0.5: set = set_connector_depth
@abstract func set_connector_depth(newDepth: float) -> void
# distance to floor in voxels from lowest y-point on connector mesh
@export_range(0.0,10.0,0.5, "or_greater", "prefer_slider") var voxelDistanceToFloor: float = 0.0
# don't need distance to ceiling, so only track if connector is touching
@export var voxelBordersCeiling: bool = false

# props that use editor-set vars to get worldspace units
var globalWidth: float: get = get_global_width
func get_global_width(): return float(voxelWidth) * Const.VOXEL
var globalHeight: float: get = get_global_height
func get_global_height(): return float(voxelHeight) * Const.VOXEL
var globalDepth: float: get = get_global_depth
func get_global_depth(): return float(voxelDepth) * Const.VOXEL
var halfWidth: float: get = get_half_width
func get_half_width(): return globalWidth / 2.0
var halfHeight: float: get = get_half_height
func get_half_height(): return globalHeight / 2.0
var halfDepth: float: get = get_half_depth
func get_half_depth(): return globalDepth / 2.0
var localSpace: Rect2:
    get: return Rect2(0.0,0.0,globalWidth,globalHeight)

# Edge meshes are generated when hole overlaps surface edge
# Disable to prevent z-fighting with existing geometry
@export_group('Generate Edges', 'edgeGen')
@export var edgeGenWest: bool = true
@export var edgeGenNorth: bool = true
@export var edgeGenEast: bool = true
@export var edgeGenSouth: bool = true
# edge collision usually exists, false by default. Only generates collison for enabled edges
@export var edgeGenCollision: bool = false

# materials for hole edges generated in the middle of the surface
@export_group('Inner Edge Materials', 'innerEdge')
@export var innerEdgeWestMaterial: StandardMaterial3D = Wallpaper01WorldMaterial
@export var innerEdgeNorthMaterial: StandardMaterial3D = Wallpaper01WorldMaterial
@export var innerEdgeEastMaterial: StandardMaterial3D = Wallpaper01WorldMaterial
@export var innerEdgeSouthMaterial: StandardMaterial3D = Wallpaper01WorldMaterial

# materials for hole edges generated at the outer edge of the surface
@export_group('Far Edge Materials', 'farEdge')
@export var farEdgeWestMaterial: StandardMaterial3D = Wallpaper01WorldMaterial
@export var farEdgeNorthMaterial: StandardMaterial3D = DropCeilingRectangle01WorldMaterial
@export var farEdgeEastMaterial: StandardMaterial3D = Wallpaper01WorldMaterial
@export var farEdgeSouthMaterial: StandardMaterial3D = Carpet01WorldMaterial

# definition passed to levelgen
@export var definition: ConnectorDefinition = null

# Refs grabbed on ready
@onready var staticBody: StaticBody3D = $Collider
@onready var collider: CollisionShape3D = $Collider/RectCollider
@onready var mesh: MeshInstance3D = $Mesh
@onready var adjacent: Area3D = $Adjacent
@onready var adjacentCollider: CollisionShape3D = $Adjacent/RectCollider

# per-instance levelgen output
var generatedProps: GeneratedConnector = null
var resolvedType: Const.ConnectorType:
    get:
        if generatedProps == null: return Const.ConnectorType.SIMPLE
        return generatedProps.type
var resolvedSubType: Const.ConnectorSubType:
    get:
        if generatedProps == null: return Const.ConnectorSubType.EMPTY
        return generatedProps.subType

# runtime local state
var adjacentAABB: AABB
var surfaceOffsetInNormal: float
var generatedColliders: Array[CollisionShape3D]
var generatedMeshes: Array[MeshInstance3D]
var coplanarConnectors: Array[RoomConnector]

@abstract func get_center_offset() -> Vector3
@abstract func get_local_hole_position(corner1: Vector3, corner2: Vector3) -> Vector2
@abstract func get_local_hole_end(corner1: Vector3, corner2: Vector3) -> Vector2
@abstract func get_center_relative_to_parent(surfaceRect: Rect2, centerOffset: Vector3) -> Vector3
@abstract func build_geometry_for_surface(surfaceRect: Rect2, centerOffset: Vector3) -> void
@abstract func build_geometry_for_hole(hole: Rect2, centerOffset: Vector3) -> void
@abstract func on_other_connector_entered(body: Area3D) -> void

func _ready() -> void:
    if Engine.is_editor_hint():
        var room: Room = Utils.get_parent_of_type(self, Room)
        var isInSubRoom: bool = false
        if room != null:
            isInSubRoom = Utils.get_parent_of_type(room, Room) != null
        if editorHelper == null: editorHelper = ConnectorEditorHelper.new(self)
        if definition == null: definition = ConnectorDefinition.new()
        if isInSubRoom && definition.name == name:
            definition = definition.duplicate()
            var newName = StringName(EditorInterface.get_edited_scene_root().get_path_to(self, true))
            definition.name = newName
        voxelWidth = voxelWidth
        voxelHeight = voxelHeight
        voxelDepth = voxelDepth
        return
    adjacentAABB = AABB()
    adjacentAABB.position = to_global(adjacentCollider.position - (adjacentCollider.shape.size / 2.0))
    adjacentAABB.end = to_global(adjacentCollider.position + (adjacentCollider.shape.size / 2.0))
    adjacentAABB = adjacentAABB.abs()
    coplanarConnectors = []
    generatedColliders = []
    generatedMeshes = []
    adjacent.area_exited.connect(on_other_connector_exited)
    adjacent.area_entered.connect(on_other_connector_entered)

func on_other_connector_exited(body: Area3D):
    var parentIndex = coplanarConnectors.find(body.get_parent())
    if parentIndex != -1:
        coplanarConnectors.remove_at(parentIndex)

# Punch hole for every coplanar connector and store metadata about it
# assumes holes never overlap with half voxel gaps
# returns true if at least one connector was made
func build_connectors() -> bool:
    if coplanarConnectors.size() == 0: return false
    var holesInLocalSpace: Array[Rect2] = []
    # shapes work from center, but AABB and Rect2 work from the corners
    var centerOffset = get_center_offset()
    for nextConnector in coplanarConnectors:
        if adjacentAABB.is_equal_approx(nextConnector.adjacentAABB):
            holesInLocalSpace.append(localSpace)
            continue
        var intersection: AABB = adjacentAABB.intersection(nextConnector.adjacentAABB)
        # put AABB intersection into local space and offset the center
        var corner1 = to_local(intersection.position) + centerOffset
        var corner2 = to_local(intersection.end) + centerOffset
        # transform into 2d surface coordinates
        # Origin from top left of plane. Wrap Y around shape height so this works
        var localHolePosition = get_local_hole_position(corner1, corner2)
        var localHoleEnd = get_local_hole_end(corner1, corner2)
        var localHoleSize = localHoleEnd - localHolePosition
        if localHoleSize.x * localHoleSize.y > 0.1:
            holesInLocalSpace.append(Rect2(localHolePosition,localHoleSize))
    # exit early if coplanar surfaces had trouble forming holes
    if holesInLocalSpace.size() == 0: return false
    # exit early if this connector gets removed entirely
    if holesInLocalSpace[0].is_equal_approx(localSpace):
        disable_default_geometry(true)
        return true
    # holes form a subsurface, generate 2d planes to fill the voids (expensive)
    var surfacesInLocalSpace = generate_surfaces_around_holes(localSpace.size, holesInLocalSpace)
    for nextSurface in surfacesInLocalSpace:
        build_geometry_for_surface(nextSurface, centerOffset)
    for nextHole in holesInLocalSpace:
        build_geometry_for_hole(nextHole, centerOffset)
    disable_default_geometry()
    return coplanarConnectors.size() > 0

# duplicate reference collider and move it into position
func new_collider(_position: Vector3, _size: Vector3):
    var newCollider: CollisionShape3D = collider.duplicate()
    newCollider.shape = collider.shape.duplicate()
    staticBody.add_child(newCollider)
    newCollider.shape.size = _size
    newCollider.position = _position
    generatedColliders.append(newCollider)
    return newCollider

# duplicate reference mesh and move it into position
func new_mesh(_position: Vector3, _size: Vector2, _material: BaseMaterial3D = null, _rotateXDeg: float = 0.0, _rotateYDeg: float = 0.0, _rotateZDeg: float = 0.0) -> MeshInstance3D:
    var newMesh: MeshInstance3D = mesh.duplicate()
    newMesh.mesh = mesh.mesh.duplicate()
    self.add_child(newMesh)
    newMesh.mesh.size = _size
    newMesh.position = _position
    if _material != null: newMesh.material_override = _material
    if !Utils.equalsf(0.0,_rotateXDeg): newMesh.rotate_x(deg_to_rad(_rotateXDeg))
    if !Utils.equalsf(0.0,_rotateYDeg): newMesh.rotate_y(deg_to_rad(_rotateYDeg))
    if !Utils.equalsf(0.0,_rotateZDeg): newMesh.rotate_z(deg_to_rad(_rotateZDeg))
    generatedMeshes.append(newMesh)
    return newMesh

func disable_default_geometry(_generateEdges: bool = false):
    collider.process_mode = Node.PROCESS_MODE_DISABLED
    collider.set_deferred("disabled", true)
    collider.hide()
    mesh.process_mode = Node.PROCESS_MODE_DISABLED
    mesh.hide()

# assumes holes already transformed to local surface coords (0,0,width,height)
# call very conservatively, probably worse than O(2^n)
func generate_surfaces_around_holes(surfaceSize: Vector2, allHoles: Array[Rect2]) -> Array[Rect2]:
    var xStopsSet: Dictionary[float, bool] = {0: true, surfaceSize.x: true}
    var yStopsSet: Dictionary[float, bool] = {0: true, surfaceSize.y: true}
    for nextHole in allHoles:
        xStopsSet.set(snappedf(nextHole.position.x, Const.HALF_VOXEL), true)
        xStopsSet.set(snappedf(nextHole.end.x, Const.HALF_VOXEL), true)
        yStopsSet.set(snappedf(nextHole.position.y, Const.HALF_VOXEL), true)
        yStopsSet.set(snappedf(nextHole.end.y, Const.HALF_VOXEL), true)
    var xStops: Array[float] = xStopsSet.keys()
    var yStops: Array[float] = yStopsSet.keys()
    xStops.sort()
    yStops.sort()
    #voxelize the space
    var voxels: Array[Rect2] = []
    var voxelRowSize = xStops.size()-1
    var voxelColumnSize = yStops.size()-1
    for yi: int in yStops.size():
        if yi == voxelColumnSize: continue
        var y1 = yStops[yi]
        var y2 = yStops[yi+1]
        for xi: int in xStops.size():
            if xi == voxelRowSize: continue
            var x1 = xStops[xi]
            var x2 = xStops[xi+1]
            var thisVoxel = Rect2(x1,y1,x2-x1,y2-y1)
            var collidesWithHole = false
            for nextHole in allHoles:
                collidesWithHole = Utils.rect_intersectsf(nextHole, thisVoxel)
                if collidesWithHole: break
            # omit voxels that collide with a hole. Result is only voxels that need filled.
            if collidesWithHole:
                voxels.append(Rect2())
            else:
                voxels.append(thisVoxel)
    # every non-null voxel gets turned into a surface. merge as much as possible
    var generatedSurfaces: Array[Rect2] = []
    # loop through every voxel
    for xi: int in voxelRowSize:
        for yi: int in voxelColumnSize:
            var voxelIndex = Utils.coordIndex(xi,yi,voxelRowSize)
            # skip null voxels (already filled or used)
            if !voxels[voxelIndex]: continue
            var workingVoxel = voxels[voxelIndex]
            voxels[voxelIndex] = Rect2()
            # first, merge down as far as possible
            var expandedByRowsCount = 0
            for myi: int in range(yi+1,voxelColumnSize):
                var mergeVoxelIndex = Utils.coordIndex(xi,myi,voxelRowSize)
                if !voxels[mergeVoxelIndex]: break
                workingVoxel = workingVoxel.merge(voxels[mergeVoxelIndex])
                voxels[mergeVoxelIndex] = Rect2()
                expandedByRowsCount += 1
            # next, test expanding one column at a time until collision with hole
            for mxi: int in range(xi+1, voxelRowSize):
                var mergeVoxelIndex = Utils.coordIndex(mxi,yi,voxelRowSize)
                if !voxels[mergeVoxelIndex]: break # break immediately if known bad
                var tryExpand: Rect2 = workingVoxel.merge(voxels[mergeVoxelIndex])
                var collidesWithHole = false
                for nextHole in allHoles:
                    collidesWithHole = Utils.rect_intersectsf(nextHole, tryExpand)
                    if collidesWithHole: break
                if collidesWithHole: break
                workingVoxel = tryExpand
                # clear merged voxel and voxels below it that the working voxel now contains
                for clearYIndex in range(yi,yi+expandedByRowsCount+1):
                    var clearVoxelIndex = Utils.coordIndex(mxi,clearYIndex,voxelRowSize)
                    voxels[clearVoxelIndex] = Rect2()
            generatedSurfaces.append(workingVoxel)
    # filled space array now contains maximally merged planes. Use those for runtime wall geometry
    return generatedSurfaces
