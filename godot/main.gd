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
    if ClassDB.class_exists("Steam"):
        return
    await RenderingServer.frame_post_draw
    var folderPath: String = "user://screenshots"
    var fileName: String = str(ProjectSettings.get("application/config/name")) + "_" + str(Time.get_unix_time_from_system()) + ".png"
    var fullPath: String = folderPath + "/" + fileName
    if not DirAccess.dir_exists_absolute(folderPath):
        DirAccess.make_dir_absolute(folderPath)
    var image: Image = get_viewport().get_texture().get_image()
    var error: Error = image.save_png(fullPath)
    if error != OK: print("screenshot failed: ", error)
