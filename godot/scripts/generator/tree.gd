class_name TreeLevelGenerator extends AbstractLevelGenerator

var roomDefinitions: Array[RoomDefinition]

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

func reinit(_room_def: RoomDefinition, s: int):
    rngSeed = s

func generate_in_radius(chunk_pos: Vector3i, chunk_radius: int):
    # Find all ungenerated chunks in this radius
    # Find all connections in ungenerated chunks
    # Resolve all found connections with randomly generated rooms

    var connections = chunkTracker[chunk_pos]
    if connections != null and connections.is_empty():
        return []

    var toGenerate: Array[Vector3i] = []
    for x in range(chunk_pos.x - chunk_radius, chunk_pos.x + chunk_radius):
        for y in range(chunk_pos.y - chunk_radius, chunk_pos.y + chunk_radius):
            for z in range(chunk_pos.z - chunk_radius, chunk_pos.z + chunk_radius):
                var cur_chunk = Vector3i(x, y, z)
                connections = chunkTracker[cur_chunk]
                if connections != null and connections.size() > 1:
                    toGenerate.append(cur_chunk)
    if toGenerate.is_empty():
        return []
    # TODO: sort toGenerate array

    var ret = []
    for chunk in toGenerate:
        ret.append_array(generate_chunk_unchecked(chunk, chunkTracker[chunk]))

    return ret

func generate_chunk(chunk: Vector3i):
    var connections = chunkTracker[chunk]

    if connections != null and connections.size() > 1:
        return generate_chunk_unchecked(chunk, connections)
    else:
        return []

func generate_chunk_unchecked(chunk: Vector3i, connections: PackedInt64Array):
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
            var new_size = connections.size() - 1
            connections.set(i, connections[new_size])
            connections.resize(new_size)
        continue

    var rng = RandomNumberGenerator.new()
    rng.seed = hash(Vector4i(rngSeed, chunk.x, chunk.y, chunk.z))

    while !connections.is_empty():
        i = rng.rand_weighted(connectionSampler)
        var _connection = unresolved_connections[connections[i] & 0xFFFFFFFF]

        var new_size = connections.size() - 1
        connections.set(i, connections[new_size])
        connections.resize(new_size)
        connectionSampler.set(i, connectionSampler[new_size])
        connectionSampler.resize(new_size)

        # Resolve connection
    return []
