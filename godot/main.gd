extends Node3D
class_name Main

@onready var viewport = get_tree().root
@onready var mainMenu = $MainMenu
@onready var pauseMenu = $PauseMenu
@onready var hudMenu = $HUDMenu

const levelScene = preload("res://base_level.tscn")

func _ready() -> void:
    mainMenu.start_game_pressed.connect(new_game)
    pauseMenu.goto_main_menu.connect(main_menu)
    SignalBus.game_exited.connect(quit_game)
    SignalBus.game_unpaused.connect(continue_game)
    SignalBus.game_paused.connect(pause_menu)
    # debug
    new_game()

func main_menu() -> void:
    get_tree().paused = false
    hudMenu.hide()
    pauseMenu.hide()
    mainMenu.show()

func new_game() -> void:
    mainMenu.hide()
    hudMenu.show()
    State.reinit()
    State.loadedLevel = levelScene.instantiate()
    get_tree().root.add_child.call_deferred(State.loadedLevel)

func quit_game() -> void:
    get_tree().quit()

func continue_game() -> void:
    get_tree().paused = false
    pauseMenu.hide()
    hudMenu.show()
    State.player.capture_mouse()

func pause_menu() -> void:
    get_tree().paused = true
    hudMenu.hide()
    pauseMenu.show()
