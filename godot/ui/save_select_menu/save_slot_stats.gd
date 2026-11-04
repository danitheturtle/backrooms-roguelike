extends Node
class_name SaveSlotStats

var index: int
var customName: String
var runCount: int
var totalScore: int
var playTime: float
var lastSavedTime: float
var gameVersion: String

# fully typesafe in case user manually fucks up their save file
func _init(savegameData: Dictionary):
    index = 0 if !savegameData.has("index") else savegameData.index
    gameVersion = "" if !savegameData.has("gameVersion") else savegameData.gameVersion
    customName = "" if !savegameData.has("customName") else savegameData.customName
    runCount = 0 if !savegameData.has("runs") else savegameData.runs.size()
    totalScore = 0 if !savegameData.has("totalScore") else savegameData.totalScore
    playTime = 0.0 if !savegameData.has("playTime") else savegameData.playTime
    lastSavedTime = 0.0 if !savegameData.has("lastSavedTime") else savegameData.lastSavedTime
