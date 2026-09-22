extends CanvasLayer
class_name MainMenu

@onready var continueButton: Button = $CenterContainer/VBoxContainer/ContinueButton
@onready var newGameButton = $CenterContainer/VBoxContainer/NewGameButton
@onready var loadGameButton: Button = $CenterContainer/VBoxContainer/LoadGameButton
@onready var tutorialButton: Button = $CenterContainer/VBoxContainer/TutorialButton
@onready var settingsButton: Button = $CenterContainer/VBoxContainer/SettingsButton
@onready var quitButton = $CenterContainer/VBoxContainer/QuitButton

func _ready() -> void:
    SignalBus.goto_main_menu.connect(on_goto_main_menu)
    newGameButton.button_up.connect(on_new_game_pressed)
    tutorialButton.button_up.connect(on_tutorial_pressed)
    settingsButton.button_up.connect(on_settings_pressed)
    quitButton.button_up.connect(on_quit_pressed)
    continueButton.button_up.connect(on_continue_pressed)
    loadGameButton.button_up.connect(on_load_game_pressed)
    on_goto_main_menu()

func on_goto_main_menu() -> void:
    if SaveSlot.savesOnDisk.keys().size() > 0:
        continueButton.show()
        loadGameButton.show()
    else:
        continueButton.hide()
        loadGameButton.hide()

func on_continue_pressed() -> void:
    # go directly to latest save
    SaveSlot.load_stats_for_saves_on_disk()
    if SaveSlot.savesOnDisk.keys().size() > 0:
        SaveSlot.load_slot(SaveSlot.sortedSaves[0].index)

func on_new_game_pressed() -> void:
    SaveSlot.load_stats_for_saves_on_disk()
    SaveSlot.new_slot(SaveSlot.first_empty_slot_index())

func on_load_game_pressed() -> void:
    SaveSlot.load_stats_for_saves_on_disk()
    SignalBus.goto_save_select_menu.emit(Enum.MenuType.MAIN)

func on_tutorial_pressed() -> void:
    SignalBus.tutorial_started.emit()

func on_settings_pressed() -> void:
    SignalBus.goto_settings_menu.emit(Enum.MenuType.MAIN)

func on_quit_pressed() -> void:
    SignalBus.game_exited.emit()
