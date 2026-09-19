extends CanvasLayer
class_name SaveSelectMenu

const SaveSlotButtonScene: PackedScene = preload("res://ui/save_select_menu/save_slot_button/save_slot_button.tscn")

@onready var cancelButton: Button = $HBoxContainer/VBoxContainer/MarginContainer2/CancelButton
@onready var slotButtonsContainer: HFlowContainer = $HBoxContainer/VBoxContainer/HBoxContainer
@onready var newGameButton: Button = $HBoxContainer/VBoxContainer/HBoxContainer/NewGameButton

var previousMenu: Enum.MenuType

func _ready() -> void:
    var saveSlotsStats = SaveSlot.savesOnDisk.values()
    for nextSaveSlot: SaveSlotStats in saveSlotsStats:
        var nextButton = SaveSlotButtonScene.instantiate()
        slotButtonsContainer.add_child(nextButton)
        nextButton.hydrate(nextSaveSlot)
    slotButtonsContainer.move_child(newGameButton, saveSlotsStats.size())
    cancelButton.pressed.connect(on_cancel_pressed)
    newGameButton.pressed.connect(on_new_game_pressed)

func on_cancel_pressed():
    SignalBus.goto_previous_menu.emit(previousMenu)

func on_new_game_pressed():
    SaveSlot.new_slot(SaveSlot.first_empty_slot_index())
