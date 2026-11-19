class_name RoomGeneratorMetadata

var connectorSampler: PackedFloat32Array = PackedFloat32Array()

var connectorCardinalIndices: Array[PackedInt32Array] = [PackedInt32Array(), PackedInt32Array(), PackedInt32Array()]
var connectorCardinalSamplers: Array[PackedFloat32Array] = [PackedFloat32Array(), PackedFloat32Array(), PackedFloat32Array()]

func select_connectors(normal: Const.CardinalDirection) -> int:
    if !Utils.is_vertical(normal):
        return 0
    elif normal == Const.CardinalDirection.YNEG:
        return 1
    else:
        return 2
