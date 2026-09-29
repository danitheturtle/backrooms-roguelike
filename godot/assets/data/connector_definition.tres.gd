class_name ConnectorDefinition
extends Resource

var name: StringName
var subType: Const.RoomConnectorSubType
var biome: Const.BiomeType
var position: Vector3
var depth: float
var distFromFloor: float
var bordersCeiling: bool
var normal: Vector3
var size: Vector2
var cornerMin: Vector3
var cornerMax: Vector3

var aabb: AABB #this is for debug testing and will go away
