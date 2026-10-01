class_name GeneratedRoom

# one room can be instanced multiple times with a different setup. differentiate them by ID
static var instanceCounter: int = 0
var roomInstanceId: StringName = "room_-1"
# unique room scene name
var sceneName: StringName = ""
# copied from room definition, needed by dynamic rooms
var dynamicRoomData: Dictionary[StringName, Variant] = {}

# don't call directly, get_generated_instance() from RoomDefinition instead
func _init(_definition: RoomDefinition) -> void:
    sceneName = _definition.sceneName
    dynamicRoomData = _definition.dynamicRoomData
    roomInstanceId = "room_" + str(instanceCounter)
    instanceCounter += 1

###
### Set by level generator
###
# global room position
var placedPosition: Vector3 = Vector3.ZERO
# Forward normal vector for room orientation. All rooms are built with normal facing forward
var placedForwardNormal: Vector3 = Vector3.FORWARD
# set by level generator and used by room sub-generator
var placedAtIteration: int = -1
# generatedConnectors tell the room how to change each connector from the default value
var generatedConnectors: Dictionary[StringName, GeneratedConnector] = {}
# tells room what should *definitely* spawn
var spawnGameplayProp: Dictionary[Const.GameplayPropType, bool] = {}
# adjusted prop spawn weight for room sub-generator
var propDensity: float = 1.0
# optional. used instead of defaults for sub-room generator prop spawning.
# intended for creating large areas with a specific "vibe"
# every prop has a unique name. things from GameplayPropType can always spawn
var customPropWeights: Dictionary[StringName, float] = {}
# optional parameter for wiring up puzzles. RoomInstanceId or ConnectorInstanceId
# With this approach there's a limitation of one solution trigger per room but that's ok.
# "solved" can be any activatable thing in the room from a puzzle to a button to 
# powering up a generator. intentionally generic
var onSolvedListenerIDs: Array[StringName] = []
