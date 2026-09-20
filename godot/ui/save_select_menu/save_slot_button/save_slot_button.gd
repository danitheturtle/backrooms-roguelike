extends Button
class_name SaveSlotButton

var data: SaveSlotStats = null
var hydrated = false

@onready var saveNameLabel: Label = $MarginContainer/VBoxContainer/SaveNameLabel
@onready var saveScoreLabel: Label = $MarginContainer/VBoxContainer/SaveScoreLabel
@onready var runCountLabel: Label = $MarginContainer/VBoxContainer/RunCountLabel
@onready var playTimeLabel: Label = $MarginContainer/VBoxContainer/PlayTimeLabel
@onready var lastSavedTimeLabel: Label = $MarginContainer/VBoxContainer/LastSavedTimeLabel

func _ready() -> void:
    pressed.connect(on_save_slot_pressed)

func hydrate(_data: SaveSlotStats):
    data = _data
    saveNameLabel.text = _data.customName
    saveScoreLabel.text = "Score: " + str(_data.totalScore)
    runCountLabel.text = "Runs: " + str(_data.runCount)
    playTimeLabel.text = "Playtime: " + str(_data.playTime)
    lastSavedTimeLabel.text = "Saved: " + str(_data.lastSavedTime)
    hydrated = true

func on_save_slot_pressed() -> void:
    if !hydrated: return
    SaveSlot.load_slot(data.index)
