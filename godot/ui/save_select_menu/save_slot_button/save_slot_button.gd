extends Button
class_name SaveSlotButton

var saveSlotStats: SaveSlotStats = null
var hydrated = false

@onready var saveNameLabel: Label = $MarginContainer/VBoxContainer/SaveNameLabel
@onready var saveScoreLabel: Label = $MarginContainer/VBoxContainer/SaveScoreLabel
@onready var runCountLabel: Label = $MarginContainer/VBoxContainer/RunCountLabel
@onready var playTimeLabel: Label = $MarginContainer/VBoxContainer/PlayTimeLabel
@onready var lastSavedTimeLabel: Label = $MarginContainer/VBoxContainer/LastSavedTimeLabel

func _ready() -> void:
    button_up.connect(on_save_slot_up)

func hydrate(data: SaveSlotStats):
    saveSlotStats = data
    saveNameLabel.text = data.customName
    saveScoreLabel.text = "Score: " + str(data.totalScore)
    runCountLabel.text = "Runs: " + str(data.runCount)
    playTimeLabel.text = "Playtime: " + str(data.playTime)
    lastSavedTimeLabel.text = "Saved: " + str(data.lastSavedTime)
    hydrated = true

func on_save_slot_up() -> void:
    if !hydrated: return
    SaveSlot.load_slot(saveSlotStats.index)
