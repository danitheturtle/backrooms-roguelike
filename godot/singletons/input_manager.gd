extends Node

var mode: Const.InputMode
var mouseCaptured: bool
var lastInputDevice: int

func _init() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    # TODO platform check and set initial input mode
    mode = Const.InputMode.MOUSE_AND_KEYBOARD
    mouseCaptured = false

func _ready() -> void:
    SignalBus.game_paused.connect(on_game_paused)
    SignalBus.game_unpaused.connect(on_game_unpaused)

func _input(event: InputEvent) -> void:
    var eventHandled = false
    if (event.is_action_pressed("toggle_fullscreen")):
        var currentWindowMode = DisplayServer.window_get_mode()
        if currentWindowMode == DisplayServer.WINDOW_MODE_WINDOWED:
            DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
            eventHandled = true
        elif currentWindowMode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
            DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
            eventHandled = true
    elif (event.is_action_pressed("screenshot")):
        take_screenshot()
        eventHandled = true
    # cursor capture. lets player get mouse back to interact with UI
    elif (event.is_action_pressed("capture_cursor") && !mouseCaptured && !get_tree().paused):
        capture_mouse()
        eventHandled = true
    elif (event.is_action_pressed("toggle_cursor")):
        if (mouseCaptured):
            release_mouse()
        else:
            capture_mouse()
        eventHandled = true
    if (eventHandled):
        get_tree().root.set_input_as_handled()

func on_game_paused() -> void:
    release_mouse()

func on_game_unpaused() -> void:
    capture_mouse()

func release_mouse() -> void:
    Input.set_mouse_mode(Input.MouseMode.MOUSE_MODE_VISIBLE)
    mouseCaptured = false

func capture_mouse() -> void:
    Input.set_mouse_mode(Input.MouseMode.MOUSE_MODE_CAPTURED)
    mouseCaptured = true

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
