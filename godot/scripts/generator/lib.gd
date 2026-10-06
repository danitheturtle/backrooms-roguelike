@abstract class_name AbstractLevelGenerator

const CHUNK_SIDE_LEN = 256

@abstract func update_definitions(roomDefs: Array[RoomDefinition])

@abstract func reinit(startingRoom: RoomDefinition)

@abstract func generate_in_radius(chunkPos: Vector3i, chunkRadius: int) -> Array[GeneratedRoom]
