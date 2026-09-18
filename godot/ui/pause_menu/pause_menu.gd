extends CanvasLayer
class_name PauseMenu

@onready var continueButton = $CenterContainer/VBoxContainer/ContinueButton
@onready var settingsButton = $CenterContainer/VBoxContainer/SettingsButton
@onready var mainMenuButton = $CenterContainer/VBoxContainer/MainMenuButton
@onready var quitButton = $CenterContainer/VBoxContainer/QuitButton
@onready var seedLabel: Label = $CenterContainer/VBoxContainer/SeedLabel

func _ready() -> void:
    visibility_changed.connect(on_visibility_changed)
    continueButton.button_up.connect(on_continue_pressed)
    mainMenuButton.button_up.connect(on_main_menu_pressed)
    settingsButton.button_up.connect(on_settings_pressed)
    quitButton.button_up.connect(on_quit_pressed)

func _unhandled_key_input(event: InputEvent) -> void:
    var eventHandled = false
    if (visible && event.is_action_pressed("ui_close_dialog")):
        SignalBus.game_unpaused.emit()
        eventHandled = true
    if (eventHandled):
        get_tree().root.set_input_as_handled()

func on_visibility_changed() -> void:
    seedLabel.text = "Seed: " + str(State.rng.seed)

func on_continue_pressed() -> void:
    SignalBus.game_unpaused.emit()

func on_main_menu_pressed() -> void:
    SignalBus.goto_main_menu.emit()

func on_settings_pressed() -> void:
    SignalBus.goto_settings_menu.emit(Enum.MenuType.PAUSE)

func on_quit_pressed() -> void:
    SignalBus.game_exited.emit()
