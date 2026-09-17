extends CanvasLayer
class_name MainMenu

@onready var continueButton: Button = $CenterContainer/VBoxContainer/ContinueButton
@onready var newGameButton = $CenterContainer/VBoxContainer/NewGameButton
@onready var tutorialButton: Button = $CenterContainer/VBoxContainer/TutorialButton
@onready var settingsButton: Button = $CenterContainer/VBoxContainer/SettingsButton
@onready var quitButton = $CenterContainer/VBoxContainer/QuitButton

func _ready() -> void:
    # if no savegames, hide continue button
    continueButton.button_up.connect(on_continue_pressed)
    newGameButton.button_up.connect(on_new_game_pressed)
    tutorialButton.button_up.connect(on_tutorial_pressed)
    settingsButton.button_up.connect(on_settings_pressed)
    quitButton.button_up.connect(on_quit_pressed)

func on_new_game_pressed() -> void:
    # show save slot screen
    pass

func on_continue_pressed() -> void:
    # go directly to latest save
    pass

func on_load_game_pressed() -> void:
    # show save slots
    pass

func on_tutorial_pressed() -> void:
    SignalBus.tutorial_started.emit()

func on_settings_pressed() -> void:
    SignalBus.goto_settings_menu.emit(Main.MenuType.MAIN)

func on_quit_pressed() -> void:
    SignalBus.game_exited.emit()
