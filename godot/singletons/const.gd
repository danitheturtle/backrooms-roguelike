extends Node
# global constants
const VOXEL: float = 0.5
const HALF_VOXEL: float = VOXEL / 2.0
const QUARTER_VOXEL: float = VOXEL / 4.0
const AMBIENT_MAX: float = 0.4

# global enums
enum MenuType { MAIN, SETTINGS, SAVE_SELECT, PAUSE, HUD }
enum PopupType { INFO, WARNING, ERROR }
enum BiomeType { LEVEL_0 }
enum ScoreEventType {PHOTO, PUZZLE, EXIT, ONE_WAY}
enum ConnectorType {
    SIMPLE = 0, # Clean cut between matched connectors
    ALT_MOVEMENT = 1, # Cut modified to require alternate movement mode
    NULL_ZONE = 2, # place invisible wall. shouldn't be on critical path
    DOOR = 3, # place a door. min size 2x2 voxels
    ONE_WAY_NULL_ZONE = 4 # same as above but player can only traverse one way
}
enum ConnectorSubType {
    # SIMPLE types. Won't generate if there isn't room
    EMPTY, ARCH, DIVIDED, NARROW,
    # Force alternate movement at this connection
    ONLY_CROUCH, ONLY_CRAWL, ONLY_SQUEEZE,
    # different doors. mostly down to visual and molding difference
    DOOR_WOODEN_01, DOOR_WOODEN_02,
    # Null zone visual distinctions
    NULL_INVISIBLE, NULL_OUTLINED, NULL_LIGHTING_ERROR, NULL_PIXEL_GAP, NULL_SHIMMER
}
enum GameplayPropType {
    OBJECT_PLACEMENT_PUZZLE,
    ALT_WAVELENGTH_PUZZLE,
    LADDER,
    LADDER_FREESTANDING,
    LADDER_TALL,
    FILM_CANISTER,
    ROPE,
    BLUE_ALMOND_WATER,
    WHITE_ALMOND_WATER,
    RED_ALMOND_WATER
}

# Yellow Light Color OKHSL value ranges
const YellowLight = {
    HUE_LOWER = 0.2889,
    HUE_UPPER = 0.3083,
    SATURATION_LOWER = 0.64,
    SATURATION_UPPER = 0.93,
    LIGHTNESS_LOWER = 0.74,
    LIGHTNESS_UPPER = 0.96,
}
# const colors cannot be defined via OKHSL
const YELLOW_LIGHT_DEFAULT = Color(0.945, 0.938, 0.49, 1.0)
const YELLOW_LIGHT_DEFAULT_BOUNCE = Color(0.966, 0.929, 0.516, 1.0)
