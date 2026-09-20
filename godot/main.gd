extends Node3D
class_name Main

@onready var viewport := get_tree().root

const LevelManagerScene = preload("res://level_manager.tscn")
const MenuManagerClass = preload("res://scripts/menu_manager.gd")

var menuManager: MenuManager

func _ready() -> void:
    get_tree().paused = true
    menuManager = MenuManagerClass.new($MainMenu, $SettingsMenu, $SaveSelectMenu, $PauseMenu, $HUDMenu)
    SignalBus.game_exited.connect(on_game_exited)
    SignalBus.game_paused.connect(on_game_paused)
    SignalBus.game_unpaused.connect(on_game_unpaused)
    SignalBus.new_run_started.connect(on_new_run_started)
    SignalBus.tutorial_started.connect(on_tutorial_started)
    SignalBus.game_paused.emit()
    # init state
    State.reinit()
    # init level manager
    State.levelManager = LevelManagerScene.instantiate()
    get_tree().root.add_child.call_deferred(State.levelManager)
    State.levelManager.reinit()
    # debug
    SignalBus.new_run_started.emit.call_deferred()


###
### Game State Transitions
###
func on_new_run_started() -> void:
    menuManager.mainMenu.process_mode = Node.PROCESS_MODE_DISABLED
    menuManager.saveSelectMenu.process_mode = Node.PROCESS_MODE_DISABLED
    menuManager.mainMenu.hide()
    menuManager.saveSelectMenu.hide()
    State.levelManager.reinit()
    get_tree().paused = false
    State.levelManager.generate_initial_level()
    # TODO show loading screen here
    await State.levelManager.level_ready
    # once ready, put player in game
    menuManager.hudMenu.show()
    State.player.capture_mouse.call_deferred()

func on_tutorial_started() -> void:
    State.levelManager.reinit()
    get_tree().paused = false
    State.levelManager.load_tutorial()
    await State.levelManager.level_ready
    menuManager.mainMenu.process_mode = Node.PROCESS_MODE_DISABLED
    menuManager.mainMenu.hide()
    menuManager.hudMenu.show()
    State.player.capture_mouse.call_deferred()

func on_game_exited() -> void: get_tree().quit()

func on_game_paused() -> void: get_tree().paused = true

func on_game_unpaused() -> void:
    get_tree().paused = false
    SignalBus.goto_hud_menu.emit()
    State.player.capture_mouse()

func _unhandled_input(event: InputEvent) -> void:
    var eventHandled = false
    if (event.is_action_pressed("toggle_fullscreen")):
        var currentWindowMode = DisplayServer.window_get_mode()
        if currentWindowMode == DisplayServer.WINDOW_MODE_WINDOWED:
            DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
            eventHandled = true
        elif currentWindowMode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
            DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
            eventHandled = true
    if (event.is_action_pressed("screenshot")):
        take_screenshot()
        eventHandled = true
    if (eventHandled):
        get_tree().root.set_input_as_handled()

func take_screenshot():
    if ClassDB.class_exists("Steam"): return
    await RenderingServer.frame_post_draw
    var folderPath: String = "user://screenshots"
    var fileName: String = str(ProjectSettings.get("application/config/name")) + "_" + str(Time.get_unix_time_from_system()) + ".png"
    var fullPath: String = folderPath + "/" + fileName
    if not DirAccess.dir_exists_absolute(folderPath):
        DirAccess.make_dir_absolute(folderPath)
    var image: Image = get_viewport().get_texture().get_image()
    var error: Error = image.save_png(fullPath)
    if error != OK: print("screenshot failed: ", error)
