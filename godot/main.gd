class_name Main
extends Node3D

@onready var viewport := get_tree().root
@onready var mainMenu: MainMenu = $MainMenu

const LevelRootScene = preload("res://level_root.tscn")

func _ready() -> void:
    get_tree().paused = true
    MenuManager.init_from_main($MainMenu, $SettingsMenu, $SaveSelectMenu, $PauseMenu, $HUDMenu)
    SignalBus.game_exited.connect(on_game_exited)
    SignalBus.game_paused.connect(on_game_paused)
    SignalBus.game_unpaused.connect(on_game_unpaused)
    SignalBus.goto_main_menu.connect(on_goto_main_menu)
    SignalBus.new_run_started.connect(on_new_run_started)
    SignalBus.tutorial_started.connect(on_tutorial_started)
    SignalBus.game_paused.emit()
    # init state and level manager
    State.reinit()
    LevelManager.reinit()
    # debug
    #mainMenu.on_tutorial_pressed.call_deferred()

func create_level_root() -> void:
    LevelManager.root = LevelRootScene.instantiate()
    add_child.call_deferred(LevelManager.root)

###
### Game State Transitions
###
func on_new_run_started() -> void:
    MenuManager.mainMenu.process_mode = Node.PROCESS_MODE_DISABLED
    MenuManager.saveSelectMenu.process_mode = Node.PROCESS_MODE_DISABLED
    MenuManager.mainMenu.hide()
    MenuManager.saveSelectMenu.hide()
    create_level_root()
    LevelManager.reinit()
    get_tree().paused = false
    LevelManager.generate_initial_level()
    # TODO show loading screen here
    await LevelManager.level_ready
    # once ready, put player in game
    MenuManager.hudMenu.show()
    InputManager.capture_mouse.call_deferred()

func on_tutorial_started() -> void:
    create_level_root()
    LevelManager.reinit()
    get_tree().paused = false
    LevelManager.load_tutorial()
    await LevelManager.level_ready
    MenuManager.mainMenu.process_mode = Node.PROCESS_MODE_DISABLED
    MenuManager.mainMenu.hide()
    MenuManager.hudMenu.show()
    InputManager.capture_mouse.call_deferred()

func on_game_exited() -> void:
    get_tree().quit()

func on_game_paused() -> void:
    get_tree().paused = true

func on_game_unpaused() -> void:
    get_tree().paused = false
    SignalBus.goto_hud_menu.emit()

func on_goto_main_menu() -> void:
    LevelManager.root.queue_free()
