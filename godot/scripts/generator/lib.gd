@abstract class_name AbstractLevelGenerator

# Inform this level generator instance of a new set of room definitions to use for level generation.
# This method must be called once before calling any generate methods (generate_in_radius, generate_chunk).
# Only the room definitions past in the most recent call to this method will be used for level generation,
# any previous room definitions will be replace and dropped.
@abstract func update_definitions(roomDefs: Array[RoomDefinition])

# Reinitialize this level generator to a state where only one room is spawned in the level,
# deleting all previously generated rooms. rngSeed will be used to seed this level generator's
# internal RNG. The same level will be generated if startingRoom and rngSeed are the same and
# all generate methods are called in the same order on the same chunks.
# `startingRoomIdx` must be a valid index into the `roomDefs` array last passed to `update_definitions`.
# `chunkRadius` is the radius around the player/generator to generate chunks within. This parameter
# is used exclusively by `generate_in_radius`.
@abstract func reinit(startingRoomIdx: int, rngSeed: int, chunkRadius: int) -> GeneratedRoom

# Queue all chunks within the cubic radius `chunkRadius` of `chunkPos` to be generated.
# The level generator will choose the ideal order in which to generate each chunk.
# This method relies on previously generated connections in nearby chunks.
# If called on chunks too far away from previously generated chunks this will fail to generate rooms.
# Chunks that have previously been queued to generate will not be queued again.
# Returns `true` if any chunk was successfully queued to be generate.
@abstract func generate_in_radius(chunkPos: Vector3i) -> bool

# Quene the specific chunk at `chunkPos` to be generated.
# This method relies on previously generated connections in nearby chunks.
# If called on a chunk too far away from previously generated chunks this will fail to generate rooms.
# Chunks that have previously been queued to generate will not be queued again.
# Returns `true` if the chunk was successfully queued to be generate.
@abstract func generate_chunk(chunkPos: Vector3i) -> bool

# Generate rooms from the chunk queue one at a time. This function will return a newly generated room
# until the queue is completely empty. When the queue is empty this function will return `null`.
# Repeatedly call this function until it returns `null` to fully empty the chunk queue.
# The level generator maintains references to the generated rooms returned by this function,
# it expects them to be treated as read-only.
@abstract func resolve_generation() -> GeneratedRoom
