class_name TreeLevelGenerator extends AbstractLevelGenerator

const MAX_ROOM_REJECTIONS: int = 16
const MAX_CONNECTOR_REJECTIONS: int = 16

var roomDefinitions: Array[RoomDefinition]
var roomMetadata: Array[RoomGeneratorMetadata]
var roomSampler: PackedFloat32Array

var rngSeed: int = 0

var placementIteration: int = 0

# append-only array of all generated rooms. Chunk trackers will hold indices into this array.
var generatedRooms: Array[GeneratedRoom] = []

var chunkTracker: Dictionary[Vector3i, ChunkTracker] = {}

func update_definitions(roomDefs: Array[RoomDefinition]):
    roomDefinitions = roomDefs
    roomSampler = PackedFloat32Array()
    roomMetadata = []
    for room in roomDefinitions:
        var metadata := RoomGeneratorMetadata.new()
        metadata.connectorSampler.resize(room.connectors.size())
        for j in range(0, room.connectors.size()):
            var connector := room.connectors[j]
            metadata.connectorSampler.set(j, connector.selectionWeight)

            var conIdx := metadata.map_connector_set(connector.normal)

            metadata.connectorCardinalIndices[conIdx].append(j)
            metadata.connectorCardinalSamplers[conIdx].append(connector.selectionWeight)

        roomMetadata.append(metadata)
        roomSampler.append(room.spawnWeight)

func reinit(startingRoomIdx: int, s: int) -> GeneratedRoom:
    var roomDef := roomDefinitions[startingRoomIdx]

    rngSeed = s
    generatedRooms = []
    chunkTracker = {}
    placementIteration = 0

    var ret := GeneratedRoom.new(roomDef)
    ret.roomDefIdx = startingRoomIdx
    # Currently the starting room can be generated with default values.
    var retIdx = generatedRooms.size()
    generatedRooms.append(ret)

    for i in range(0, roomDef.connectors.size()):
        var connector := roomDef.connectors[i]
        var cur_chunk := Utils.world_to_chunk(connector.position)

        var new_tracker := get_tracker(cur_chunk)

        var new_unresolved := UnresolvedConnection.new()
        new_unresolved.generatedRoomIdx = retIdx
        new_unresolved.roomConnectorIdx = i
        new_tracker.unresolved.append(new_unresolved)

    return ret

func stable_sort_chunks(array: Array[Vector3i], center: Vector3i):
    # Unless the radius gets very big insertion sort will be most efficient.
    for i in range(1, array.size()):
        for j in range(i, 0, -1):
            var a = array[j - 1]
            var b = array[j]
            if a.distance_squared_to(center) > b.distance_squared_to(center):
                array[j - 1] = b
                array[j] = a
            else:
                break

func generate_in_radius(chunk_pos: Vector3i, chunk_radius: int) -> Array[GeneratedRoom]:
    var tracker := chunkTracker[chunk_pos]
    # If the player/generator has already visited this chunk, early exit this call.
    if tracker != null and tracker.isVisited:
        return []

    var toGenerate: Array[Vector3i] = []
    for x in range(chunk_pos.x - chunk_radius, chunk_pos.x + chunk_radius):
        for z in range(chunk_pos.z - chunk_radius, chunk_pos.z + chunk_radius):
            for y in range(chunk_pos.y - chunk_radius, chunk_pos.y + chunk_radius):
                var cur_chunk := Vector3i(x, y, z)
                var cur_tracker := chunkTracker[cur_chunk]
                if cur_tracker != null and !cur_tracker.unresolved.is_empty():
                    toGenerate.append(cur_chunk)
    if toGenerate.is_empty():
        tracker.isVisited = true
        return []

    # We want to generate from the center going outwards.
    stable_sort_chunks(toGenerate, chunk_pos)

    var ret = []
    for chunk in toGenerate:
        ret.append_array(generate_chunk_unchecked(chunk, chunkTracker[chunk]))

    tracker.isVisited = true
    return ret

func generate_chunk(chunk_pos: Vector3i) -> Array[GeneratedRoom]:
    var tracker := chunkTracker[chunk_pos]
    if tracker != null and !tracker.unresolved.is_empty():
        return generate_chunk_unchecked(chunk_pos, tracker)
    else:
        # Since no chunks were generated in a radius around `chunk` we do not try to mark it as visited.
        return []

# This function expects to be passed the array of connections from `chunkTracker` associated with the given chunk.
func generate_chunk_unchecked(chunk_pos: Vector3i, tracker: ChunkTracker) -> Array[GeneratedRoom]:
    var all_unresolved := tracker.unresolved

    # Collect all possible connections along with their weights.
    var connectionSampler := PackedFloat32Array()
    connectionSampler.resize(all_unresolved.size())
    for i in range(0, all_unresolved.size()):
        var unresolved := all_unresolved[i]
        var roomDef := roomDefinitions[unresolved.generatedRoomIdx]
        var connector := roomDef.connectors[unresolved.roomConnectorIdx]
        connectionSampler.set(i, connector.selectionWeight)

    # We seed this rng call for increased level gen determinism.
    var rng := RandomNumberGenerator.new()
    rng.seed = hash(Vector4i(rngSeed, chunk_pos.x, chunk_pos.y, chunk_pos.z))

    var ret = []

    # Resolve all connections in this chunk.
    while !all_unresolved.is_empty():
        var i := rng.rand_weighted(connectionSampler)
        var cur_unresolved := all_unresolved[i]

        # Swap remove the selected connection from the sampler (sample without replacement).
        var newSize := all_unresolved.size() - 1
        all_unresolved.set(i, all_unresolved[newSize])
        all_unresolved.resize(newSize)
        connectionSampler.set(i, connectionSampler[newSize])
        connectionSampler.resize(newSize)

        var curRoom := generatedRooms[cur_unresolved.generatedRoomIdx]
        var curRoomDef := roomDefinitions[curRoom.roomDefIdx]
        var curConnectorDef := curRoomDef.connectors[cur_unresolved.roomConnectorIdx]

        # Rejection sample a room to generate connected to the selected connection.
        # Currently this samples with replacement.
        # If rejection sampling fails, we assume the connector cannot be resolved and remove it.
        for j in range(0, MAX_ROOM_REJECTIONS):
            var newRoomDefIdx := rng.rand_weighted(roomSampler)
            var newRoomDef := roomDefinitions[newRoomDefIdx]
            var newRoomMetadata := roomMetadata[newRoomDefIdx]

            var conSetIdx = newRoomMetadata.map_connector_set(curConnectorDef.normal)

            # Rejection sample a connector in the selected room to be mated with the selected connector.
            for k in range(0, MAX_CONNECTOR_REJECTIONS):
                var newConnectorIdx := newRoomMetadata.connectorCardinalIndices[conSetIdx][rng.rand_weighted(newRoomMetadata.connectorCardinalSamplers[conSetIdx])]
                var newConnectorDef := newRoomDef.connectors[newConnectorIdx]

                var newRoomNormal : Const.CardinalDirection
                if conSetIdx == 0:
                    # the connection is horizontal, so reorient the room to face the connector
                    newRoomNormal = Utils.horizontal_oppose(curRoom.placedNormal, newConnectorDef.normal)
                else:
                    # the connection is vertical, so choose a random horizontal room orientation
                    newRoomNormal = rng.randi_range(0, 3) as Const.CardinalDirection

                var curConnectorCornerMin := Utils.horizontal_rotatei(curRoom.placedNormal, curConnectorDef.cornerMin)
                var curConnectorCornerMax := Utils.horizontal_rotatei(curRoom.placedNormal, curConnectorDef.cornerMax)
                var newConnectorCornerMin := Utils.horizontal_rotatei(newRoomNormal, newConnectorDef.cornerMin)
                var newConnectorCornerMax := Utils.horizontal_rotatei(newRoomNormal, newConnectorDef.cornerMax)

                var curConnectorAlignment := alignment(rng, curConnectorCornerMin, curConnectorCornerMax)
                var newConnectorAlignment := alignment(rng, newConnectorCornerMin, newConnectorCornerMax)

                var newRoomPlacedPos := curRoom.placedPosition + curConnectorAlignment - newConnectorAlignment
                var newRoomPos := Utils.voxel_to_world(newRoomPlacedPos)

                # check for intersection with any other existing room
                var newApproximateBounds := AABB(newRoomDef.newApproximateBounds)
                newApproximateBounds.position += newRoomPos
                var newBounds : Array[AABB] = []
                for a in range(0, newRoomDef.bounds.size()):
                    var bound := AABB(newRoomDef.bounds[a])
                    bound.position += newRoomPos
                    newBounds.append(bound)

                var bound_start = Utils.world_to_chunk(newApproximateBounds.position)
                var bound_end = Utils.world_to_chunk(newApproximateBounds.position + newApproximateBounds.size)
                if check_bounds(newApproximateBounds, newBounds, bound_start, bound_end):
                    # We can generate this room. This is currently the only place that can
                    # create a GeneratedRoom.
                    var newRoom := GeneratedRoom.new(newRoomDef)
                    newRoom.roomDefIdx = newRoomDefIdx
                    newRoom.placedPosition = newRoomPlacedPos
                    newRoom.placedNormal = newRoomNormal
                    newRoom.placedAtIteration = placementIteration
                    newRoom.approximateBounds = newApproximateBounds
                    newRoom.bounds = newBounds

                    var newGeneratedConnector := GeneratedConnector.new(newConnectorDef, newRoom.roomInstanceId)
                    newRoom.generatedConnectors.append(newGeneratedConnector)

                    var curGeneratedConnector := GeneratedConnector.new(curConnectorDef, curRoom.roomInstanceId)
                    curRoom.generatedConnectors.append(curGeneratedConnector)

                    # Add the room to each intersecting chunk tracker.
                    var newGeneratedRoomIdx = generatedRooms.size()
                    generatedRooms.append(newRoom)
                    for x in range(bound_start.x, bound_end.x):
                        for z in range(bound_start.z, bound_end.z):
                            for y in range(bound_start.y, bound_end.y):
                                var newTracker := get_tracker(Vector3i(x, y, z))
                                newTracker.generated.append(newGeneratedRoomIdx)

                    # Add each new connector to each intersecting chunk tracker.
                    for newConIdx in range(0, newRoomDef.connectors.size()):
                        var newConnector := newRoomDef.connectors[newConIdx]
                        var newCornerMin = Utils.horizontal_rotatei(newRoomNormal, newConnector.cornerMin) + newRoomPlacedPos
                        var newTracker := get_tracker(Utils.voxel_to_chunk(newCornerMin))
                        var newUnresolved := UnresolvedConnection.new()
                        newUnresolved.generatedRoomIdx = newGeneratedRoomIdx
                        newUnresolved.roomConnectorIdx = newConIdx
                        newTracker.unresolved.append(newUnresolved)

                    ret.append(newRoom)
    if !ret.is_empty():
        placementIteration += 1
    return ret

func alignment(rng: RandomNumberGenerator, cornerMin: Vector3i, cornerMax: Vector3i) -> Vector3i:
    var cornerAlignment := Vector3i.ZERO
    if cornerMin.x + 1 < cornerMax.x - 1:
        cornerAlignment.x = rng.randi_range(cornerMin.x + 1, cornerMax.x - 1)
    else:
        cornerAlignment.x = (cornerMin.x + cornerMax.x) / 2
    if cornerMin.y + 2 < cornerMax.y - 2:
        cornerAlignment.y = rng.randi_range(cornerMin.y + 2, cornerMax.y - 2)
    else:
        cornerAlignment.y = (cornerMin.y + cornerMax.y) / 2
    if cornerMin.z + 1 < cornerMax.z - 1:
        cornerAlignment.z = rng.randi_range(cornerMin.z + 1, cornerMax.z - 1)
    else:
        cornerAlignment.z = (cornerMin.z + cornerMax.z) / 2
    return cornerAlignment

func get_tracker(chunk_pos: Vector3i) -> ChunkTracker:
    var tracker := chunkTracker[chunk_pos]
    if tracker == null:
        tracker = ChunkTracker.new()
        chunkTracker[chunk_pos] = tracker
    return tracker

func check_bounds(newApproximateBounds: AABB, newBounds: Array[AABB], bound_start: Vector3i, bound_end: Vector3i):
    for x in range(bound_start.x, bound_end.x):
        for z in range(bound_start.z, bound_end.z):
            for y in range(bound_start.y, bound_end.y):
                var tracker := chunkTracker[Vector3i(x, y, z)]
                if tracker != null:
                    for l in range(0, tracker.generated.size()):
                        var generated := generatedRooms[tracker.generated[l]]
                        if newApproximateBounds.intersection(generated.approximateBounds):
                            for a in range(0, newBounds.size()):
                                for b in range(0, generated.bounds.size()):
                                    if newBounds[a].intersection(generated.bounds[b]):
                                        return false
    return true
