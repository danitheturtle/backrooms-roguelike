class_name BasicLevelGenerator extends AbstractLevelGenerator

func update_definitions(_p: Array[RoomDefinition]):
    pass

func reinit(_p: RoomDefinition, _rngSeed: int):
    pass

func generate_in_radius(_chunk_pos: Vector3i, _chunk_radius: int):
    return []

func generate_chunk(_chunkPos: Vector3i):
    return []
