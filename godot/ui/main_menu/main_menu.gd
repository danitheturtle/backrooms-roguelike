extends CanvasLayer
class_name MainMenu

signal start_game_pressed

@onready var startGameButton = $CenterContainer/VBoxContainer/StartGameButton
@onready var quitButton = $CenterContainer/VBoxContainer/QuitButton

func _ready() -> void:
    startGameButton.button_up.connect(_start_game_pressed)
    quitButton.button_up.connect(_quit_pressed)

func _start_game_pressed() -> void:
    start_game_pressed.emit()

func _quit_pressed() -> void:
    SignalBus.game_exited.emit()
