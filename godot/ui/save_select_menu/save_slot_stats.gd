extends Node
class_name SaveSlotStats

var index: int
var customName: String
var runCount: int
var totalScore: int
var playTime: float
var lastSavedTime: float

func _init(savegameData: Dictionary):
    index = savegameData.index
    customName = savegameData.customName
    runCount = savegameData.runs.size()
    totalScore = savegameData.totalScore
    playTime = savegameData.playTime
    lastSavedTime = savegameData.lastSavedTime
