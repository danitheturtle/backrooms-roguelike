class_name TreeLevelGenerator extends AbstractLevelGenerator

const MAX_ROOM_REJECTIONS: int = 16
const MAX_CONNECTOR_REJECTIONS: int = 16

var roomDefinitions: Array[RoomDefinition]
var roomMetadata: Array[RoomGeneratorMetadata]
var roomSampler: PackedFloat32Array

var rngSeed: int = 0

var chunkRadius: int = 0

var generationIteration: int = 1

var chunkTracker: Dictionary[Vector3i, ChunkTracker] = {}

var toGenerateQueue: Array[Vector3i] = []

func update_definitions(roomDefs: Array[RoomDefinition]):
    roomDefinitions = roomDefs
    roomSampler = PackedFloat32Array()
    roomMetadata = []

    generationIteration = 1
    chunkTracker = {}
    toGenerateQueue = []

    for room in roomDefinitions:
        var metadata := RoomGeneratorMetadata.new()
        metadata.connectorSampler.resize(room.connectors.size())
        for j in range(room.connectors.size()):
            var connector := room.connectors[j]
            metadata.connectorSampler.set(j, connector.selectionWeight)

            var conIdx := metadata.map_connector_set(connector.normal)

            metadata.connectorCardinalIndices[conIdx].append(j)
            metadata.connectorCardinalSamplers[conIdx].append(connector.selectionWeight)

        roomMetadata.append(metadata)
        roomSampler.append(room.spawnWeight)

func reinit(startingRoomIdx: int, s: int, r: int) -> GeneratedRoom:
    var roomDef := roomDefinitions[startingRoomIdx]

    rngSeed = s
    chunkRadius = r
    generationIteration = 1
    chunkTracker = {}
    toGenerateQueue = []

    var ret := GeneratedRoom.new(roomDef)
    ret.roomDefIdx = startingRoomIdx
    ret.approximateBounds = AABB(roomDef.approximateBounds)
    ret.bounds = roomDef.bounds.duplicate_deep()

    register_generated(ret)

    return ret

func generate_in_radius(chunkPos: Vector3i) -> bool:
    var tracker := get_tracker(chunkPos)
    # If the player/generator has already visited this chunk, early exit this call.
    if tracker.isVisited:
        return !toGenerateQueue.is_empty()
    tracker.isVisited = true

    var startIdx := toGenerateQueue.size()
    for x in range(chunkPos.x - chunkRadius, chunkPos.x + chunkRadius + 1):
        for z in range(chunkPos.z - chunkRadius, chunkPos.z + chunkRadius + 1):
            for y in range(chunkPos.y - chunkRadius, chunkPos.y + chunkRadius + 1):
                generate_chunk_uniterated(Vector3i(x, y, z))

    if startIdx < toGenerateQueue.size():
        # We want to generate from the center going outwards.
        stable_sort_chunks(chunkPos, startIdx)
        generationIteration += 1
        return true
    return !toGenerateQueue.is_empty()

# Stable sort the portion of `toGenerateQueue` from index `startIdx` to the end.
# Sort by distance from the center, closer is first.
func stable_sort_chunks(center: Vector3i, startIdx: int):
    # Unless the radius gets very big insertion sort will be most efficient.
    for i in range(startIdx + 1, toGenerateQueue.size()):
        for j in range(i, startIdx, -1):
            var a = toGenerateQueue[j - 1]
            var b = toGenerateQueue[j]
            if a.distance_squared_to(center) > b.distance_squared_to(center):
                toGenerateQueue[j - 1] = b
                toGenerateQueue[j] = a
            else:
                break

func generate_chunk(chunkPos: Vector3i) -> bool:
    var ret = generate_chunk_uniterated(chunkPos)
    if ret:
        generationIteration += 1
    return ret

func generate_chunk_uniterated(chunkPos: Vector3i) -> bool:
    var curTracker := get_tracker(chunkPos)
    if curTracker.generationIteration == 0:
        curTracker.generationIteration = generationIteration
        toGenerateQueue.append(chunkPos)
        return true
    else:
        return false

func resolve_generation() -> GeneratedRoom:
    while !toGenerateQueue.is_empty():
        var chunkPos = toGenerateQueue[0]

        # Elements of `toGenerateQueue` must have a non-null associated tracker.
        var tracker := chunkTracker[chunkPos]

        # Resolve a single connections in this chunk by rejection sampling without replacement.
        while !tracker.unresolved.is_empty():
            tracker.resolutionIterations += 1
            assert(tracker.resolutionIterations < 1000)

            # Collect all possible connections along with their weights.
            var connectionSampler := PackedFloat32Array()
            connectionSampler.resize(tracker.unresolved.size())
            for i in range(tracker.unresolved.size()):
                var unresolved := tracker.unresolved[i]
                var roomDef := roomDefinitions[unresolved.roomDefIdx]
                var connector := roomDef.connectors[unresolved.roomConnectorIdx]
                connectionSampler.set(i, connector.selectionWeight)

            var i := tracker.rng.rand_weighted(connectionSampler)
            var cur_unresolved := tracker.unresolved[i]

            # Swap remove the selected connection from the sampler (sample without replacement).
            # This swap remove must run every iteration of the while loop to guarantee function return.
            var newSize := tracker.unresolved.size() - 1
            tracker.unresolved.set(i, tracker.unresolved[newSize])
            tracker.unresolved.resize(newSize)

            var curRoom := cur_unresolved.parentRoom
            var curRoomDef := roomDefinitions[curRoom.roomDefIdx]
            var curConnectorDef := curRoomDef.connectors[cur_unresolved.roomConnectorIdx]

            # Rejection sample a room to generate connected to the selected connection.
            # Currently this samples with replacement.
            # If rejection sampling fails, we assume the connector cannot be resolved and remove it.
            for j in range(MAX_ROOM_REJECTIONS):
                var newRoomDefIdx := tracker.rng.rand_weighted(roomSampler)
                var newRoomDef := roomDefinitions[newRoomDefIdx]
                var newRoomMetadata := roomMetadata[newRoomDefIdx]

                var conSetIdx := newRoomMetadata.map_connector_set(curConnectorDef.normal)
                var conSetSampler := newRoomMetadata.connectorCardinalSamplers[conSetIdx]

                if conSetSampler.is_empty():
                    # There is no correctly oriented available connector on this room so sample again.
                    continue

                # Rejection sample a connector in the selected room to be mated with the selected connector.
                for k in range(MAX_CONNECTOR_REJECTIONS):
                    var newConnectorIdx := newRoomMetadata.connectorCardinalIndices[conSetIdx][tracker.rng.rand_weighted(conSetSampler)]
                    var newConnectorDef := newRoomDef.connectors[newConnectorIdx]

                    var newRoomNormal : Const.CardinalDirection
                    if conSetIdx == 0:
                        # the connection is horizontal, so reorient the room to face the connector
                        newRoomNormal = Utils.horizontal_oppose(curRoom.placedNormal, newConnectorDef.normal)
                    else:
                        # the connection is vertical, so choose a random horizontal room orientation
                        newRoomNormal = tracker.rng.randi_range(0, 3) as Const.CardinalDirection

                    var curConnectorCornerMin := Utils.horizontal_rotatei(curRoom.placedNormal, curConnectorDef.cornerMin)
                    var curConnectorCornerMax := Utils.horizontal_rotatei(curRoom.placedNormal, curConnectorDef.cornerMax)
                    var newConnectorCornerMin := Utils.horizontal_rotatei(newRoomNormal, newConnectorDef.cornerMin)
                    var newConnectorCornerMax := Utils.horizontal_rotatei(newRoomNormal, newConnectorDef.cornerMax)

                    var curConnectorAlignment := alignment(tracker.rng, curConnectorCornerMin, curConnectorCornerMax)
                    var newConnectorAlignment := alignment(tracker.rng, newConnectorCornerMin, newConnectorCornerMax)

                    var newRoomPlacedPos := curRoom.placedPosition + curConnectorAlignment - newConnectorAlignment
                    var newRoomPos := Utils.voxel_to_world(newRoomPlacedPos)

                    # check for intersection with any other existing room
                    var newApproximateBounds := AABB(newRoomDef.approximateBounds)
                    newApproximateBounds.position += newRoomPos
                    var newBounds : Array[AABB] = []
                    for a in range(newRoomDef.bounds.size()):
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
                        newRoom.placedAtIteration = tracker.generationIteration
                        newRoom.approximateBounds = newApproximateBounds
                        newRoom.bounds = newBounds

                        var newGeneratedConnector := GeneratedConnector.new(newConnectorDef, newRoom.roomInstanceId)
                        var curGeneratedConnector := GeneratedConnector.new(curConnectorDef, curRoom.roomInstanceId)

                        newGeneratedConnector.connectedToInstanceId = curGeneratedConnector.connectorInstanceId
                        curGeneratedConnector.connectedToInstanceId = newGeneratedConnector.connectorInstanceId

                        newRoom.generatedConnectors.append(newGeneratedConnector)
                        newRoom.updatedConnectors.append(curGeneratedConnector)

                        register_generated(newRoom)

                        return newRoom
        tracker.isGenerated = true
        toGenerateQueue.pop_front()
    return null

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

func register_generated(newRoom: GeneratedRoom):
    var bound_start = Utils.world_to_chunk(newRoom.approximateBounds.position)
    var bound_end = Utils.world_to_chunk(newRoom.approximateBounds.position + newRoom.approximateBounds.size)

    # Increment end to change range from exclusive to inclusive.
    for x in range(bound_start.x, bound_end.x + 1):
        for z in range(bound_start.z, bound_end.z + 1):
            for y in range(bound_start.y, bound_end.y + 1):
                var newTracker := get_tracker(Vector3i(x, y, z))
                newTracker.generated.append(newRoom)

    # Add each new connector to each intersecting chunk tracker.
    var newRoomDef := roomDefinitions[newRoom.roomDefIdx]
    for newConIdx in range(newRoomDef.connectors.size()):
        var newConnector := newRoomDef.connectors[newConIdx]
        var newCornerMin = Utils.horizontal_rotatei(newRoom.placedNormal, newConnector.cornerMin) + newRoom.placedPosition
        var newTracker := get_tracker(Utils.voxel_to_chunk(newCornerMin))
        if !newTracker.isGenerated:
            var newUnresolved := UnresolvedConnection.new()
            newUnresolved.parentRoom = newRoom
            newUnresolved.roomDefIdx = newRoom.roomDefIdx
            newUnresolved.roomConnectorIdx = newConIdx
            newTracker.unresolved.append(newUnresolved)

func get_tracker(chunkPos: Vector3i) -> ChunkTracker:
    var tracker: ChunkTracker = chunkTracker.get(chunkPos)
    if tracker == null:
        tracker = ChunkTracker.new(rngSeed, chunkPos)
        chunkTracker[chunkPos] = tracker
    return tracker

func check_bounds(newApproximateBounds: AABB, newBounds: Array[AABB], bound_start: Vector3i, bound_end: Vector3i):
    # Increment end to change range from exclusive to inclusive.
    for x in range(bound_start.x, bound_end.x + 1):
        for z in range(bound_start.z, bound_end.z + 1):
            for y in range(bound_start.y, bound_end.y + 1):
                var tracker: ChunkTracker = chunkTracker.get(Vector3i(x, y, z))
                if tracker != null:
                    for generated in tracker.generated:
                        if newApproximateBounds.intersection(generated.approximateBounds):
                            for a in range(newBounds.size()):
                                for b in range(generated.bounds.size()):
                                    if newBounds[a].intersection(generated.bounds[b]):
                                        return false
    return true
