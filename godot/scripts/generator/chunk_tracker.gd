class_name ChunkTracker

# Whether the player/generator has directly visited (generated all chunks within a radius) the corresponding chunk.
# The array `unresolved` *must* be empty if this is set to `true`.
var isVisited: bool = false
# An array of unresolved connections. These are connections in rooms that have been
# generated that are under consideration for being the connection to new rooms.
var unresolved: Array[UnresolvedConnection] = []
