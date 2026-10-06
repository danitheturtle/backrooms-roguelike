@abstract class_name AbstractLevelGenerator

const CHUNK_SIDE_LEN = 256

# Inform this level generator instance of a new set of room definitions to use for level generation.
# This method must be called once before calling any generate methods (generate_in_radius, generate_chunk).
# Only the room definitions past in the most recent call to this method will be used for level generation,
# any previous room definitions will be replace and dropped.
@abstract func update_definitions(roomDefs: Array[RoomDefinition])

# Reinitialize this level generator to a state where only one room is spawned in the level,
# deleting all previously generated rooms. rngSeed will be used to seed this level generator's
# internal RNG. The same level will be generated if startingRoom and rngSeed are the same and
# all generate methods are called in the same order with the same parameters.
@abstract func reinit(startingRoom: RoomDefinition, rngSeed: int)

# Generate all chunks within the cubic radius chunkRadius of chunkPos.
#  The level generator will choose the ideal order in which to generate each chunks.
# This method relies on previously generated connections in nearby chunks.
# If called on chunks too far away from previously generated chunks this will fail to generate rooms.
@abstract func generate_in_radius(chunkPos: Vector3i, chunkRadius: int) -> Array[GeneratedRoom]

# Generate the specific chunk at chunkPos.
# This method relies on previously generated connections in nearby chunks.
# If called on a chunk too far away from previously generated chunks this will fail to generate rooms.
@abstract func generate_chunk(chunkPos: Vector3i) -> Array[GeneratedRoom]
