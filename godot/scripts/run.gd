extends Node
class_name Run

var runSeed: int = 0
var scoreEvents: Array[ScoreEvent] = []

class ScoreEvent:
    var type: Enum.ScoreEventType
    var value: int
    func _init(_type: Enum.ScoreEventType = Enum.ScoreEventType.PHOTO, _value: int = 0):
        type = _type
        value = _value
    func serialize():
        var dataDict = { "type": type, "value": value }
        return dataDict
    func deserialize(data: Dictionary[String,Variant]) -> ScoreEvent:
        type = data.type
        value = data.value
        return self

func serialize() -> Dictionary[String,Variant]:
    var dataDict = {
        "runSeed": runSeed,
        "scoreEvents": [],
    }
    for nextEvent in scoreEvents:
        dataDict.scoreEvents.append(nextEvent.serialize())
    return dataDict

func deserialize(dataDict: Dictionary[String,Variant]) -> Run:
    runSeed = dataDict.runSeed
    scoreEvents = []
    for nextEventData in dataDict.scoreEvents:
        scoreEvents.append(ScoreEvent.new().deserialize(nextEventData))
    return self
