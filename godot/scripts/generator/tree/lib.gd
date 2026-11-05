class_name TreeLevelGenerator extends AbstractLevelGenerator

const MAX_ROOM_REJECTIONS: int = 16
const MAX_CONNECTOR_REJECTIONS: int = 8

var roomDefinitions: Array[RoomDefinition]
var roomMetadata: Array[RoomGeneratorMetadata]
var roomSampler: PackedFloat32Array

var rngSeed: int = 0

var generatedRooms: Array[GeneratedRoom] = []

# When an entry is an empty array, the player/generator has directly visited (generated all chunks within a radius) the corresponding chunk.
# When an entry is an array of size 1 (containing only 0), the corresponding chunk is fully generated but has not been directly visited by a player.
# In all other cases the array contains indices for unresolved generated connections existing in the
# corresponding chunk (except for index 0 which will contain value 0).
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

            metadata.cardinal_connector_indices[connector.normal].append(j)
            metadata.cardinal_connector_samplers[connector.normal].append(connector.selectionWeight)

        roomMetadata.append(metadata)
        roomSampler.append(room.spawnWeight)

func reinit(startingRoomIdx: int, s: int) -> GeneratedRoom:
    var roomDef := roomDefinitions[startingRoomIdx]

    rngSeed = s
    generatedRooms = []
    chunkTracker = {}

    var ret := GeneratedRoom.new(roomDef)
    ret.roomDefIdx = startingRoomIdx
    # Currently the starting room can be generated with default values
    var retIdx = generatedRooms.size()
    generatedRooms.append(ret)

    for i in range(0, roomDef.connectors.size()):
        var connector := roomDef.connectors[i]
        var cur_chunk := Utils.world_to_chunk(connector.position)

        var new_tracker := chunkTracker[cur_chunk]
        if new_tracker == null:
            new_tracker = ChunkTracker.new()
            chunkTracker[cur_chunk] = new_tracker

        var new_unresolved := UnresolvedConnection.new()
        new_unresolved.generatedRoomIdx = retIdx
        new_unresolved.roomConnectorIdx = i
        new_tracker.unresolved.append(new_unresolved)

    return ret

func stable_sort_chunks(array: Array[Vector3i], center: Vector3i):
    # Unless the radius gets very big insertion sort will be most efficient
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
    # Find all ungenerated chunks in this radius
    # Find all connections in ungenerated chunks
    # Resolve all found connections with randomly generated rooms

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

    # We want to generate from the center going outwards
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
        # Since no chunks were generated in a radius around `chunk` we do not try to mark it as visited
        return []

# This function expects to be passed the array of connections from `chunkTracker` associated with the given chunk
func generate_chunk_unchecked(chunk_pos: Vector3i, tracker: ChunkTracker) -> Array[GeneratedRoom]:
    var all_unresolved := tracker.unresolved

    # Collect all possible connections along with their weights
    var connectionSampler := PackedFloat32Array()
    connectionSampler.resize(all_unresolved.size())
    for i in range(0, all_unresolved.size()):
        # Skip index 0 which is always 0
        var unresolved := all_unresolved[i]
        var roomDef := roomDefinitions[unresolved.generatedRoomIdx]
        var connector := roomDef.connectors[unresolved.roomConnectorIdx]
        connectionSampler.set(i, connector.selectionWeight)

    # We seed this rng call for increased level gen determinism
    var rng := RandomNumberGenerator.new()
    var chunk_seed := hash(Vector4i(rngSeed, chunk_pos.x, chunk_pos.y, chunk_pos.z))
    rng.seed = chunk_seed

    var ret = []

    # Resolve all connections in this chunk
    while !all_unresolved.is_empty():
        var i := rng.rand_weighted(connectionSampler)
        var cur_unresolved := all_unresolved[i]

        # Swap remove the selected connection from the sampler (sample without replacement)
        var newSize := all_unresolved.size() - 1
        all_unresolved.set(i, all_unresolved[newSize])
        all_unresolved.resize(newSize)
        connectionSampler.set(i, connectionSampler[newSize])
        connectionSampler.resize(newSize)

        var curRoom := generatedRooms[cur_unresolved.generatedRoomIdx]
        var curRoomDef := roomDefinitions[curRoom.roomDefIdx]
        var curConnectorDef := curRoomDef.connectors[cur_unresolved.roomConnectorIdx]

        # Rejection sample a room to generate connected to the selected connection
        for j in range(0, MAX_ROOM_REJECTIONS):
            var newRoomDefIdx := rng.rand_weighted(roomSampler)
            var newRoomDef := roomDefinitions[newRoomDefIdx]
            var newRoomMetadata := roomMetadata[newRoomDefIdx]
            # Rejection sample a connector in the selected room to be mated with the selected connector
            for k in range(0, MAX_CONNECTOR_REJECTIONS):
                var newConnectorIdx := rng.rand_weighted(newRoomMetadata.connectorSampler)
                var newConnector := newRoomDef.connectors[newConnectorIdx]

                newConnector.cornerMax



        # Resolve connection
    return ret
