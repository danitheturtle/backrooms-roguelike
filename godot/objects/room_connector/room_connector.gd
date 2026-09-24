@tool
@abstract
extends Node3D
class_name RoomConnector

const Wallpaper01WorldMaterial = preload("res://assets/materials/Wallpaper01/Wallpaper01_world.tres")

# basic bounds
@export_range(0.5, 16.0, 0.5, "or_greater") var connectionWidth: float = 3.0: set = set_connection_width
func set_connection_width(newWidth: float) -> void: #only one that's the same for all connections
    if editorHelper != null: editorHelper.update_connection_width(newWidth, "x")
    connectionWidth = newWidth
@export_range(0.5, 16.0, 0.5, "or_greater") var connectionHeight: float = 3.0: set = set_connection_height
@abstract func set_connection_height(newHeight: float) -> void
@export_range(0.25,8.0,0.25, "or_greater") var connectionDepth: float = 0.25: set = set_connection_depth
@abstract func set_connection_depth(newDepth: float) -> void

# Edge meshes are generated when hole overlaps surface edge
# Disable to prevent z-fighting with existing geometry
@export_group('Generate Edges', 'wallFor')
@export var wallForWestEdge: bool = true
@export var wallForNorthEdge: bool = true
@export var wallForEastEdge: bool = true
@export var wallForSouthEdge: bool = true

@export_group('Inner Edge Materials', 'innerEdge')
@export var innerEdgeWestMaterial: StandardMaterial3D = Wallpaper01WorldMaterial
@export var innerEdgeNorthMaterial: StandardMaterial3D = Wallpaper01WorldMaterial
@export var innerEdgeEastMaterial: StandardMaterial3D = Wallpaper01WorldMaterial
@export var innerEdgeSouthMaterial: StandardMaterial3D = Wallpaper01WorldMaterial

# connection metadata for the level generator
@export_group('Connection Metadata', 'meta')
# what connection sub-type is this? Unused for now
@export_enum("SIMPLE") var metaSubType: String = "SIMPLE"
# what biome does this connection work in? Unused for now
@export_enum("LEVEL_0") var metaBiome: String = "LEVEL_0"

@onready var staticBody: StaticBody3D = $Collider
@onready var collider: CollisionShape3D = $Collider/RectCollider
@onready var mesh: MeshInstance3D = $Mesh
@onready var adjacent: Area3D = $Adjacent
@onready var adjacentCollider: CollisionShape3D = $Adjacent/RectCollider

var adjacentAABB: AABB
var surfaceOffsetInNormal: float
var generatedColliders: Array[CollisionShape3D]
var generatedMeshes: Array[MeshInstance3D]
var coplanarConnections: Array[RoomConnector]

var editorHelper: RoomConnectorEditorHelper = null
var localSpace: Rect2:
    get: return Rect2(0.0,0.0,connectionWidth,connectionHeight)

@abstract func get_center_offset() -> Vector3
@abstract func get_local_hole_position(corner1: Vector3, corner2: Vector3) -> Vector2
@abstract func get_local_hole_end(corner1: Vector3, corner2: Vector3) -> Vector2
@abstract func get_center_relative_to_parent(surfaceRect: Rect2, centerOffset: Vector3) -> Vector3
@abstract func build_geometry_for_surface(surfaceRect: Rect2, centerOffset: Vector3) -> void
@abstract func build_geometry_for_hole(hole: Rect2, centerOffset: Vector3) -> void
@abstract func on_other_connection_entered(body: Area3D) -> void

func _ready() -> void:
    if Engine.is_editor_hint():
        editorHelper = RoomConnectorEditorHelper.new(self)
        return
    adjacentAABB = AABB()
    adjacentAABB.position = to_global(adjacentCollider.position - (adjacentCollider.shape.size / 2.0))
    adjacentAABB.end = to_global(adjacentCollider.position + (adjacentCollider.shape.size / 2.0))
    adjacentAABB = adjacentAABB.abs()
    coplanarConnections = []
    generatedColliders = []
    generatedMeshes = []
    adjacent.area_exited.connect(on_other_connection_exited)
    adjacent.area_entered.connect(on_other_connection_entered)
    await get_tree().physics_frame
    await get_tree().physics_frame
    # TODO move to level manager
    build_connections()

func on_other_connection_exited(body: Area3D):
    var parentIndex = coplanarConnections.find(body.get_parent())
    if parentIndex != -1:
        coplanarConnections.remove_at(parentIndex)

# Punch hole for every coplanar connection and store metadata about it
# assumes holes never overlap with .5 voxel (0.25) gaps
# returns true if at least one connection was made
func build_connections() -> bool:
    if coplanarConnections.size() == 0: return false
    var holesInLocalSpace: Array[Rect2] = []
    # shapes work from center, but AABB and Rect2 work from the corners
    var centerOffset = get_center_offset()
    for nextConnection in coplanarConnections:
        if adjacentAABB.is_equal_approx(nextConnection.adjacentAABB):
            holesInLocalSpace.append(localSpace)
            continue
        var intersection: AABB = adjacentAABB.intersection(nextConnection.adjacentAABB)
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
    # exit early if this connection gets removed entirely
    if holesInLocalSpace[0].is_equal_approx(localSpace):
        disable_default_geometry(true)
        return true
    # holes form a subsurface, generate 2d planes to fill the voids (expensive)
    var surfacesInLocalSpace = generate_surfaces_around_holes(localSpace.size, holesInLocalSpace)
    #if surfacesInLocalSpace.size() == 0:
        #disable_default_geometry(true)
        #return true
    for nextSurface in surfacesInLocalSpace:
        build_geometry_for_surface(nextSurface, centerOffset)
    for nextHole in holesInLocalSpace:
        build_geometry_for_hole(nextHole, centerOffset)
    disable_default_geometry()
    return coplanarConnections.size() > 0

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
        xStopsSet.set(snappedf(nextHole.position.x, 0.25), true)
        xStopsSet.set(snappedf(nextHole.end.x, 0.25), true)
        yStopsSet.set(snappedf(nextHole.position.y, 0.25), true)
        yStopsSet.set(snappedf(nextHole.end.y, 0.25), true)
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
