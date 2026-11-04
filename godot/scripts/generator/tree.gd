class_name TreeLevelGenerator extends AbstractLevelGenerator

const MAX_REJECTIONS: int = 8

var roomDefinitions: Array[RoomDefinition]
var roomMetadata: Array[RoomMetadata]
var roomSampler: PackedFloat32Array

var rngSeed: int

var connection_generation: int

var generated_rooms: Array[GeneratedRoom]

# A generational array of unresolved connections. These are connections in rooms that have been
# generated that are under consideration for being the connection to new rooms.
# Each element of a generational array contains a "generation" number, which is a monotonically increasing counter.
# Generation numbers allow "pointers" (indices paired with a generation number) into this array to be lazily invalidated.
var unresolved_connections: Array[UnresolvedConnection]

# When an entry is an empty array, the player/generator has directly visited (generated all chunks within a radius) the corresponding chunk.
# When an entry is an array of size 1 (containing only 0), the corresponding chunk is fully generated but has not been directly visited by a player.
# In all other cases the array contains indices for unresolved generated connections existing in the
# corresponding chunk (except for index 0 which will contain value 0).
# These are generational indices into the `unresolved_connections` array.
var chunkTracker: Dictionary[Vector3i, PackedInt64Array]

var definitions: Array[RoomDefinition] = LevelManager.allDefinitions

func update_definitions(roomDefs: Array[RoomDefinition]):
    roomDefinitions = roomDefs
    roomSampler = PackedFloat32Array()
    roomMetadata = []
    for room in roomDefinitions:
        var metadata = RoomMetadata.new()
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
    # If the player/generator has already visited this chunk, early exit this call.
    if connections != null and connections.is_empty():
        return []

    var toGenerate: Array[Vector3i] = []
    for x in range(chunk_pos.x - chunk_radius, chunk_pos.x + chunk_radius):
        for z in range(chunk_pos.z - chunk_radius, chunk_pos.z + chunk_radius):
            for y in range(chunk_pos.y - chunk_radius, chunk_pos.y + chunk_radius):
                var cur_chunk = Vector3i(x, y, z)
                var cur_connections = chunkTracker[cur_chunk]
                if cur_connections != null and cur_connections.size() > 1:
                    toGenerate.append(cur_chunk)
    if toGenerate.is_empty():
        # Mark this chunk as visited
        connections.clear()
        return []

    # We want to generate from the center going outwards
    stable_sort_chunks(toGenerate, chunk_pos)

    var ret = []
    for chunk in toGenerate:
        ret.append_array(generate_chunk_unchecked(chunk, chunkTracker[chunk]))

    # Mark this chunk as visited
    connections.clear()
    return ret

func generate_chunk(chunk: Vector3i) -> Array[GeneratedRoom]:
    var connections = chunkTracker[chunk]

    if connections != null and connections.size() > 1:
        return generate_chunk_unchecked(chunk, connections)
    else:
        # Since no chunks were generated in a radius around `chunk` we do not try to mark it as visited
        return []

# This function expects to be passed the array of connections from `chunkTracker` associated with the given chunk
func generate_chunk_unchecked(chunk: Vector3i, connections: PackedInt64Array) -> Array[GeneratedRoom]:
    # Collect all possible connections along with their weights
    var connectionSampler = PackedFloat32Array()
    connectionSampler.resize(connections.size())
    var i = 0
    while i < connections.size():
        # Skip index 0 which is always 0
        var genIdx = connections[i + 1]
        var generation = genIdx >> 32
        var connection = unresolved_connections[genIdx & 0xFFFFFFFF]
        # Incorrect generation indicates this connection was deleted previously
        if connection.generation == generation:
            connectionSampler.set(i, connection.weight)
            i += 1
        else:
            # swap remove the outdated connection
            var newSize = connections.size() - 1
            connections.set(i + 1, connections[newSize])
            connections.resize(newSize)
        continue

    # We seed this rng call for increased level gen determinism
    var rng = RandomNumberGenerator.new()
    var chunk_seed = hash(Vector4i(rngSeed, chunk.x, chunk.y, chunk.z))
    rng.seed = chunk_seed

    var ret = []

    # Resolve all connections in this chunk
    while connections.size() > 1:
        i = rng.rand_weighted(connectionSampler)
        var genIdx = connections[i + 1]
        var connection = unresolved_connections[genIdx & 0xFFFFFFFF]

        # Swap remove the selected connection from the sampler (sample without replacement)
        var newSize = connections.size() - 1
        connections.set(i + 1, connections[newSize])
        connections.resize(newSize)
        connectionSampler.set(i, connectionSampler[newSize])
        connectionSampler.resize(newSize)

        var preRoomDef = roomDefinitions[connection.room_idx]
        var preConnectorDef = preRoomDef.connectors[connection.connector_key]

        # Rejection sample a room to generate connected to the selected connection
        for j in range(0, MAX_REJECTIONS):
            var newRoomIdx = rng.rand_weighted(roomSampler)
            var newRoomDef = roomDefinitions[newRoomIdx]
            var newRoomMetadata = roomMetadata[newRoomIdx]
            # Rejection sample a connector in the selected room to be mated with the selected connector
            for k in range(0, MAX_REJECTIONS):
                var newConnectorIdx = rng.rand_weighted(newRoomMetadata.connectorSampler)
                var newConnector = newRoomDef.connectors[newConnectorIdx]



        # Resolve connection
    return ret
