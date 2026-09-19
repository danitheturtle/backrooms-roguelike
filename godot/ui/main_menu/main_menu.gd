extends CanvasLayer
class_name MainMenu

@onready var continueButton: Button = $CenterContainer/VBoxContainer/ContinueButton
@onready var newGameButton = $CenterContainer/VBoxContainer/NewGameButton
@onready var loadGamebutton: Button = $CenterContainer/VBoxContainer/LoadGameButton
@onready var tutorialButton: Button = $CenterContainer/VBoxContainer/TutorialButton
@onready var settingsButton: Button = $CenterContainer/VBoxContainer/SettingsButton
@onready var quitButton = $CenterContainer/VBoxContainer/QuitButton

func _ready() -> void:
    # if no savegames, hide continue button
    continueButton.button_up.connect(on_continue_pressed)
    newGameButton.button_up.connect(on_new_game_pressed)
    loadGamebutton.button_up.connect(on_load_game_pressed)
    tutorialButton.button_up.connect(on_tutorial_pressed)
    settingsButton.button_up.connect(on_settings_pressed)
    quitButton.button_up.connect(on_quit_pressed)

func on_continue_pressed() -> void:
    # go directly to latest save
    SaveSlot.load_stats_for_saves_on_disk()
    pass

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
