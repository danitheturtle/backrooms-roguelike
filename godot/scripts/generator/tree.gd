class_name TreeLevelGenerator extends AbstractLevelGenerator

const MAX_REJECTIONS: int = 8

var roomDefinitions: Array[RoomDefinition]
var roomMetadata: Array[RoomMetadata]
var roomSampler: PackedFloat32Array

var rngSeed: int

var connection_generation: int

var generated_rooms: Array[GeneratedRoom]

var unresolved_connections: Array[UnresolvedConnection]

# When an entry is an empty array, the player/algorithm has directly visited the corresponding chunk.
# When an entry is an array of size 1, the corresponding chunk is fully generated but has not been directly visited.
# In all other cases the array contains indices for unresolved generated connections existing in the corresponding chunk (except for index 0 which will contain value 0).
var chunkTracker: Dictionary[Vector3i, PackedInt64Array]

var definitions: Array[RoomDefinition] = LevelManager.allDefinitions

func update_definitions(roomDefs: Array[RoomDefinition]):
    roomDefinitions = roomDefs
    roomSampler = PackedFloat32Array()
    roomMetadata = []
    for room in roomDefinitions:
        var metadata: RoomMetadata
        metadata.connectorSampler.resize(room.connectors.size())
        for j in range(0, room.connectors.size()):
            var connector = room.connectors[j]
            metadata.connectorSampler.set(j, connector.selectionWeight)

        roomMetadata.append(metadata)
        roomSampler.append(room.spawnWeight)

func reinit(_room_def: RoomDefinition, s: int):
    rngSeed = s

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

    var connections = chunkTracker[chunk_pos]
    if connections != null and connections.is_empty():
        return []

    var toGenerate: Array[Vector3i] = []
    for x in range(chunk_pos.x - chunk_radius, chunk_pos.x + chunk_radius):
        for z in range(chunk_pos.z - chunk_radius, chunk_pos.z + chunk_radius):
            for y in range(chunk_pos.y - chunk_radius, chunk_pos.y + chunk_radius):
                var cur_chunk = Vector3i(x, y, z)
                connections = chunkTracker[cur_chunk]
                if connections != null and connections.size() > 1:
                    toGenerate.append(cur_chunk)
    if toGenerate.is_empty():
        return []

    # We want to generate from the center going outwards
    stable_sort_chunks(toGenerate, chunk_pos)

    var ret = []
    for chunk in toGenerate:
        ret.append_array(generate_chunk_unchecked(chunk, chunkTracker[chunk]))

    return ret

func generate_chunk(chunk: Vector3i) -> Array[GeneratedRoom]:
    var connections = chunkTracker[chunk]

    if connections != null and connections.size() > 1:
        return generate_chunk_unchecked(chunk, connections)
    else:
        return []

func generate_chunk_unchecked(chunk: Vector3i, connections: PackedInt64Array) -> Array[GeneratedRoom]:
    var connectionSampler = PackedFloat32Array()
    connectionSampler.resize(connections.size())
    var i = 0
    while i < connections.size():
        var genIdx = connections[i]
        var generation = genIdx >> 32
        var connection = unresolved_connections[genIdx & 0xFFFFFFFF]
        if connection.generation == generation:
            connectionSampler.set(i, connection.weight)
            i += 1
        else:
            # swap remove the outdated connection
            var newSize = connections.size() - 1
            connections.set(i, connections[newSize])
            connections.resize(newSize)
        continue

    var rng = RandomNumberGenerator.new()
    rng.seed = hash(Vector4i(rngSeed, chunk.x, chunk.y, chunk.z))

    var ret = []

    while !connections.is_empty():
        i = rng.rand_weighted(connectionSampler)
        var genIdx = connections[i]
        var connection = unresolved_connections[genIdx & 0xFFFFFFFF]

        # Swap remove connection from sampler
        var newSize = connections.size() - 1
        connections.set(i, connections[newSize])
        connections.resize(newSize)
        connectionSampler.set(i, connectionSampler[newSize])
        connectionSampler.resize(newSize)

        var preRoomDef = roomDefinitions[connection.room_idx]
        var preConnectorDef = preRoomDef.connectors[connection.connector_key]

        for j in range(0, MAX_REJECTIONS):
            # TODO: seed this rng call for increased determinism
            var newRoomIdx = rng.rand_weighted(roomSampler)
            var newRoomDef = roomDefinitions[newRoomIdx]
            var newRoomMetadata = roomMetadata[newRoomIdx]
            for k in range(0, MAX_REJECTIONS):
                var newConnectorIdx = rng.rand_weighted(newRoomMetadata.connectorSampler)
                var newConnector = newRoomDef.connectors[newConnectorIdx]



        # Resolve connection
    return ret
