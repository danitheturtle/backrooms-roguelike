extends Button
class_name SaveSlotButton

var data: SaveSlotStats = null
var hydrated = false

@onready var saveNameLabel: Label = $MarginContainer/VBoxContainer/SaveNameLabel
@onready var saveScoreLabel: Label = $MarginContainer/VBoxContainer/HBoxContainer/SaveScoreLabel
@onready var runCountLabel: Label = $MarginContainer/VBoxContainer/HBoxContainer/RunCountLabel
@onready var playTimeLabel: Label = $MarginContainer/VBoxContainer/HBoxContainer2/PlayTimeLabel
@onready var gameVersionLabel: Label = $MarginContainer/VBoxContainer/HBoxContainer2/GameVersionLabel
@onready var lastSavedTimeLabel: Label = $MarginContainer/VBoxContainer/LastSavedTimeLabel
@onready var oldVersionColorRect: ColorRect = $OldVersionColorRect
@onready var eraseSaveButton: TextureButton = $EraseSaveButton

func _ready() -> void:
    pressed.connect(on_save_slot_pressed)
    eraseSaveButton.pressed.connect(on_erase_save_pressed)

func hydrate(_data: SaveSlotStats):
    data = _data
    saveNameLabel.text = _data.customName
    if !Utils.is_version_valid(SaveSlot.oldestCompatibleSaveVersion, _data.gameVersion):
        oldVersionColorRect.show()
        disabled = true
    saveScoreLabel.text = "Score: " + str(_data.totalScore)
    runCountLabel.text = "Runs: " + str(_data.runCount)
    playTimeLabel.text = "Playtime: " + str(_data.playTime)
    lastSavedTimeLabel.text = "Saved: " + str(_data.lastSavedTime)
    gameVersionLabel.text = "Game Version: " + str(_data.gameVersion)
    hydrated = true

func on_save_slot_pressed() -> void:
    if !hydrated || disabled: return
    SaveSlot.load_slot(data.index)

func on_erase_save_pressed() -> void:
    SaveSlot.erase_slot(data.index)
    SaveSlot.load_stats_for_saves_on_disk()
    queue_free()
