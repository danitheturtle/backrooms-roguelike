extends Node
# global constants
const VOXEL: float = 0.5
const HALF_VOXEL: float = VOXEL / 2.0
const QUARTER_VOXEL: float = VOXEL / 4.0
const AMBIENT_MAX: float = 0.4

# global enums
enum MenuType { MAIN, SETTINGS, SAVE_SELECT, PAUSE, HUD }
enum PopupType { INFO, WARNING, ERROR }
enum ScoreEventType {PHOTO, EXIT, ONE_WAY}
enum RoomConnectorSubType { SIMPLE, DOOR, LOCKED_DOOR, NULL_ZONE, ONE_WAY_NULL_ZONE }
enum SpawnableType { OBJECT_PLACEMENT_PUZZLE, LADDER, LADDER_FREESTANDING, LADDER_TALL, FILM }
enum BiomeType { LEVEL_0 }
