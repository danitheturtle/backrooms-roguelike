#class_name BackroomsGenerator
#
#const CHUNK_SIDE_LEN = 256
#
#var room_definitions: Array[RoomDefinition]
#
#var current_seed: int
#
#var connection_generation: int
#
#var generated_rooms: Array[GeneratedRoom]
#
#var unresolved_connections: Array[UnresolvedConnection]
#
#
## When an entry is an empty array, the player/algorithm has directly visited the corresponding chunk.
## When an entry is an array of size 1, the corresponding chunk is fully generated but has not been directly visited.
## In all other cases the array contains indices for unresolved generated connections existing in the corresponding chunk (except for index 0 which will contain value 0).
#var chunk_tracker: Dictionary[Vector3i, PackedInt64Array]
#
#func generate_in_radius(chunk_pos: Vector3i, chunk_radius: int):
    ## Find all ungenerated chunks in this radius
    ## Find all connections in ungenerated chunks
    ## Resolve all found connections with randomly generated rooms
#
    #var connections = chunk_tracker[chunk_pos]
    #if connections != null and connections.is_empty():
        #return
    #var to_generate = []
    #for x in range(chunk_pos.x - chunk_radius, chunk_pos.x + chunk_radius):
        #for y in range(chunk_pos.y - chunk_radius, chunk_pos.y + chunk_radius):
            #for z in range(chunk_pos.z - chunk_radius, chunk_pos.z + chunk_radius):
                #cur_chunk = Vector3i(x, y, z)
                #connections = chunk_tracker[cur_chunk]
                #if connections != null and connections.size() > 1:
                    #to_generate.append(cur_chunk)
    #if to_generate.is_emtpy():
        #return
    ## TODO: sort to_generate array
#
    #for chunk in to_generate:
        #connections = chunk_tracker[chunk]
#
        #connection_sampler = PackedFloat32Array()
        #connection_sampler.resize(connections.size())
        #i = 0
        #while i < connections.size():
            #gen_idx = connections[i]
            #generation = gen_idx >> 32
            #connection = unresolved_connections[gen_idx & 0xFFFFFFFF]
            #if connection.generation == generation:
                #connection_sampler.set(i, connection.weight)
                #i += 1
            #else:
                ## swap remove the outdated connection
                #new_size = connections.size() - 1
                #connections.set(i, connections[new_size])
                #connections.resize(new_size)
            #continue
#
        #rng = RandomNumberGenerator.new()
        #rng.seed = hash(chunk, current_seed)
        #while !connections.is_empty():
            #i = rng.rand_weighted(connection_sampler)
            #connection = unresolved_connections[connections[i] & 0xFFFFFFFF]
#
            #new_size = connections.size() - 1
            #connections.set(i, connections[new_size])
            #connections.resize(new_size)
            #connection_sampler.set(i, connection_sampler[new_size])
            #connection_sampler.resize(new_size)
#
            ## Resolve connection
            #
