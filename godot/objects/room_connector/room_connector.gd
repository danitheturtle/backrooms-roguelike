@tool
extends Node3D
class_name RoomConnector

# assumes holes already transformed to local surface coords (0,0,width,height)
# call very conservatively, probably worse than O(2^n)
func generate_surfaces_around_holes(surfaceSize: Vector2, allHoles: Array[Rect2]):
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
