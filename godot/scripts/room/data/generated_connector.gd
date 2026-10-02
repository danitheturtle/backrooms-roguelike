class_name GeneratedConnector

# unique per-run instance counter for connector and parent
static var instanceCounter: int = 0
var connectorInstanceId: StringName = "connector_-1"
var parentRoomInstanceId: StringName = "room_-1"
# room-unique connector name passed from ConnectorDefinition
var connectorName: StringName

# don't call directly, get_generated_instance() on room instead
func _init(_definition: Resource, _parentRoomInstanceId: StringName) -> void:
    connectorName = _definition.name
    type = _definition.initialType
    subType = _definition.initialSubType
    parentRoomInstanceId = _parentRoomInstanceId
    connectorInstanceId = "connector_" + str(instanceCounter)
    instanceCounter += 1

###
### Set by level generator
###
# ConnectorType defines what to place if the connector detects a match. Comparison using 
# int-based enum to determine final type of matched connector. higher wins
# If two locked doors or two one-way null zones match, one will be discarded
var type: Const.ConnectorType = Const.ConnectorType.SIMPLE
# Connector sub-type further defines how the room generates.
# If EMPTY, picks randomly based on resolved ConnectorType
var subType: Const.ConnectorSubType = Const.ConnectorSubType.EMPTY
# Lock the connector if its a lockable type
var locked: bool = false
# Spawn a draggable prop in front of the connection to obscure it, if supported
var blocked: bool = false
