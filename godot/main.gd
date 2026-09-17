extends Node3D
class_name Main

@onready var viewport := get_tree().root

enum MenuType { MAIN, SETTINGS, PAUSE, HUD }
# menus
@onready var mainMenu := $MainMenu
@onready var pauseMenu := $PauseMenu
@onready var settingsMenu := $SettingsMenu
@onready var hudMenu := $HUDMenu

const levelManagerScene = preload("res://level_manager.tscn")

func _ready() -> void:
    get_tree().paused = true
    SignalBus.goto_previous_menu.connect(on_goto_previous_menu)
    SignalBus.goto_main_menu.connect(on_goto_main_menu)
    SignalBus.goto_pause_menu.connect(on_goto_pause_menu)
    SignalBus.goto_settings_menu.connect(on_goto_settings_menu)
    SignalBus.game_exited.connect(on_game_exited)
    SignalBus.game_paused.connect(on_game_paused)
    SignalBus.game_unpaused.connect(on_game_unpaused)
    SignalBus.new_run_started.connect(on_new_run_started)
    SignalBus.tutorial_started.connect(on_tutorial_started)
    SignalBus.game_paused.emit()
    # init state
    State.reinit()
    # init level manager
    State.levelManager = levelManagerScene.instantiate()
    get_tree().root.add_child.call_deferred(State.levelManager)
    State.levelManager.reinit()
    # debug
    #SignalBus.tutorial_started.emit()


###
### Game State Transitions
###
func on_new_run_started() -> void:
    get_tree().paused = false
    State.levelManager.generate_initial_level()
    await State.levelManager.level_ready
    mainMenu.process_mode = Node.PROCESS_MODE_DISABLED
    mainMenu.hide()
    hudMenu.show()
    State.player.capture_mouse.call_deferred()

func on_tutorial_started() -> void:
    get_tree().paused = false
    State.levelManager.load_tutorial()
    await State.levelManager.level_ready
    mainMenu.process_mode = Node.PROCESS_MODE_DISABLED
    mainMenu.hide()
    hudMenu.show()
    State.player.capture_mouse.call_deferred()

func on_game_exited() -> void: get_tree().quit()

func on_game_paused() -> void: get_tree().paused = true

func on_game_unpaused() -> void:
    get_tree().paused = false
    settingsMenu.process_mode = Node.PROCESS_MODE_DISABLED
    pauseMenu.process_mode = Node.PROCESS_MODE_DISABLED
    settingsMenu.hide()
    pauseMenu.hide()
    hudMenu.show()
    State.player.capture_mouse()

###
### Menu Transitions
###
func on_goto_previous_menu(previousMenuName: MenuType):
    match previousMenuName:
        MenuType.MAIN:
            on_goto_main_menu()
        MenuType.PAUSE:
            on_goto_pause_menu()
        MenuType.SETTINGS:
            on_goto_settings_menu(previousMenuName)

func on_goto_main_menu() -> void:
    State.levelManager.reinit()
    pauseMenu.process_mode = Node.PROCESS_MODE_DISABLED
    settingsMenu.process_mode = Node.PROCESS_MODE_DISABLED
    hudMenu.hide()
    pauseMenu.hide()
    settingsMenu.hide()
    mainMenu.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
    mainMenu.show()

func on_goto_settings_menu(previousMenuName: MenuType) -> void:
    mainMenu.process_mode = Node.PROCESS_MODE_DISABLED
    pauseMenu.process_mode = Node.PROCESS_MODE_DISABLED
    mainMenu.hide()
    pauseMenu.hide()
    settingsMenu.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
    settingsMenu.previousMenu = previousMenuName
    settingsMenu.load_settings_into_controls()
    settingsMenu.show()

func on_goto_pause_menu() -> void:
    mainMenu.process_mode = Node.PROCESS_MODE_DISABLED
    settingsMenu.process_mode = Node.PROCESS_MODE_DISABLED
    hudMenu.hide()
    mainMenu.hide()
    settingsMenu.hide()
    pauseMenu.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
    pauseMenu.show()

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
