extends CanvasLayer
class_name SaveSelectMenu

const SaveSlotButtonScene: PackedScene = preload("res://ui/save_select_menu/save_slot_button/save_slot_button.tscn")

@onready var cancelButton: Button = $HBoxContainer/VBoxContainer/MarginContainer2/CancelButton
@onready var slotButtonsContainer: HFlowContainer = $HBoxContainer/VBoxContainer/HBoxContainer
@onready var newGameButton: Button = $HBoxContainer/VBoxContainer/HBoxContainer/NewGameButton

var previousMenu: Enum.MenuType

func _ready() -> void:
    SignalBus.goto_save_select_menu.connect(on_goto_save_select_menu)
    cancelButton.pressed.connect(on_cancel_pressed)
    newGameButton.pressed.connect(on_new_game_pressed)

func on_goto_save_select_menu(_previousMenu: Enum.MenuType):
    previousMenu = _previousMenu
    SaveSlot.load_stats_for_saves_on_disk()
    var buttonContainerChildren: Array[Node] = slotButtonsContainer.get_children()
    var existingSlotButtons: Dictionary[int, SaveSlotButton] = {}
    for nextSlotButton: Node in buttonContainerChildren:
        if not nextSlotButton is SaveSlotButton: continue
        if !SaveSlot.savesOnDisk.has(nextSlotButton.data.index):
            slotButtonsContainer.remove_child(nextSlotButton)
            nextSlotButton.queue_free()
        else:
            existingSlotButtons.set(nextSlotButton.data.index, nextSlotButton)
            nextSlotButton.hydrate(SaveSlot.savesOnDisk[nextSlotButton.data.index])
    var saveSlots = SaveSlot.savesOnDisk.values()
    for nextSaveSlot: SaveSlotStats in saveSlots:
        if !existingSlotButtons.has(nextSaveSlot.index):
            var nextButton = SaveSlotButtonScene.instantiate()
            slotButtonsContainer.add_child(nextButton)
            nextButton.hydrate(nextSaveSlot)
    slotButtonsContainer.move_child(newGameButton, saveSlots.size())

func on_cancel_pressed():
    SignalBus.goto_previous_menu.emit(previousMenu)

func on_new_game_pressed():
    SaveSlot.new_slot(SaveSlot.first_empty_slot_index())

func _unhandled_key_input(event: InputEvent) -> void:
    var eventHandled = false
    if (visible && event.is_action_pressed("ui_close_dialog")):
        SignalBus.goto_previous_menu.emit(previousMenu)
        eventHandled = true
    if (eventHandled):
        get_tree().root.set_input_as_handled()
