class_name ChunkTracker

# Whether the player/generator has directly visited (generated all chunks within a radius) the corresponding chunk.
# The array `unresolved` *must* be empty if this is set to `true`.
var isVisited: bool = false
# An array of unresolved connections. These are connections in rooms that have been
# generated that are under consideration for being the connection to new rooms.
# Connections are only added to the single chunk that contains its CornerMin.
# This array is unordered and may change ordering at any time.
var unresolved: Array[UnresolvedConnection] = []

# an array of indices into the `generatedRooms` append-only array. Each index is a generated room
# that intersects with this chunk
var generated: PackedInt32Array = []
