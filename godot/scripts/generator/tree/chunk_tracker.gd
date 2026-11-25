class_name ChunkTracker

# Whether the player/generator has directly visited (generated all chunks within a radius) the corresponding chunk.
# The array `unresolved` *must* be empty if this is set to `true`.
var isVisited: bool = false

# This field will be set to `true` after this chunk is fully generated and removed from the queue.
# Unresolved connections should not be appended to field `unresolved` when this is `true`.
var isGenerated: bool = false

# Changes from 0 to > 0 exactly once, when this chunk is appended to `toGenerateQueue`
# Equal to the number of successful calls to `generate_chunk` or `generate_in_radius` that occurred
# when this chunk was queued to be generated.
var generationIteration: int = 0

var rng: RandomNumberGenerator = RandomNumberGenerator.new()

# Equal to the number of iterations of connection resolution that have occurred on this chunk.
var resolutionIterations: int = 0

# An array of unresolved connections. These are connections in rooms that have been
# generated that are under consideration for being the connection to new rooms.
# Connections are only added to the single chunk that contains its CornerMin.
# This array is unordered and may change ordering at any time.
var unresolved: Array[UnresolvedConnection] = []

# an array of indices into the `generatedRooms` append-only array. Each index is a generated room
# that intersects with this chunk
var generated: Array[GeneratedRoom] = []

func _init(rngSeed: int, chunkPos: Vector3i) -> void:
    # We seed this rng call for increased level gen determinism.
    rng.seed = hash(Vector4i(rngSeed, chunkPos.x, chunkPos.y, chunkPos.z))
