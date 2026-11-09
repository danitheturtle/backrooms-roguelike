extends Node

var mouseCaptured: bool
var steamDevices: Dictionary[int, bool] = {}
var lastInputType: Const.InputType

var forwardOnLongPress: Dictionary = {}

func _init() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    # TODO platform check and set initial input mode
    lastInputType = Const.InputType.MOUSE_AND_KEYBOARD
    mouseCaptured = false
    # TODO get list of devices steam api will be sending events for
    InputMap.project_settings_loaded.connect(on_project_settings_loaded)
    SignalBus.game_paused.connect(on_game_paused)
    SignalBus.game_unpaused.connect(on_game_unpaused)
    Input.joy_connection_changed.connect(on_joy_connection_changed)
    # track long press forwarding
    forwardOnLongPress[&"crouch"] = new_long_press_action(&"crouch", &"crawl")
    forwardOnLongPress[&"action"] = new_long_press_action(&"action", &"action_wheel")

func on_project_settings_loaded() -> void:
    # TODO apply user keybind changes
    pass

func _input(event: InputEvent) -> void:
    # ensure steam api inputs are handled by steam api
    if filter_steam_input(event): return
    # determine lastInputType if it isn't steam
    if lastInputType != Const.InputType.STEAM:
        if event is InputEventJoypadButton || event is InputEventJoypadMotion:
            lastInputType = Const.InputType.JOYPAD
        elif event is InputEventScreenTouch || event is InputEventScreenDrag || event is InputEventGesture:
            lastInputType = Const.InputType.TOUCH
        else:
            lastInputType = Const.InputType.MOUSE_AND_KEYBOARD
    
    # create new events if certain actions are held
    for nextActionKey: StringName in forwardOnLongPress.keys():
        var nextForwardedAction = forwardOnLongPress[nextActionKey]
        if event.is_action_pressed(nextActionKey):
            nextForwardedAction.timerFinished = false
            nextForwardedAction.timer.start()
        elif event.is_action_released(nextActionKey):
            nextForwardedAction.timer.stop()
            if nextForwardedAction.timerFinished:
                var newEvent = InputEventAction.new()
                newEvent.action = nextForwardedAction["action"]
                newEvent.pressed = false
                Input.parse_input_event(newEvent)
    
    # handle global actions
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

## if a controller is disconnected, pause the game
func on_joy_connection_changed(_deviceId: int, connected: bool) -> void:
    if !connected && !get_tree().paused:
        if MenuManager.hudMenu.visible:
            SignalBus.goto_pause_menu.emit()
        SignalBus.game_paused.emit()

func on_long_press_timeout(_sourceAction: StringName, _forwardedAction: StringName) -> void:
    # do nothing if settings disable long press action forwarding
    if lastInputType == Const.InputType.MOUSE_AND_KEYBOARD && !GameSettings.KeyboardUsesLongPress: return
    if !GameSettings.JoypadUsesLongPress: return
    forwardOnLongPress[_sourceAction].timerFinished = true
    var newEvent = InputEventAction.new()
    newEvent.action = _forwardedAction
    newEvent.pressed = true
    Input.parse_input_event(newEvent)

func release_mouse() -> void:
    Input.set_mouse_mode(Input.MouseMode.MOUSE_MODE_VISIBLE)
    mouseCaptured = false

func capture_mouse() -> void:
    Input.set_mouse_mode(Input.MouseMode.MOUSE_MODE_CAPTURED)
    mouseCaptured = true

## eat input event and return true if event was fired by device steam is handling to prevent duplicates
func filter_steam_input(event: InputEvent) -> bool:
    if !Platform.steamEnabled: return false
    if steamDevices[event.device]:
        lastInputType = Const.InputType.STEAM
        get_tree().root.set_input_as_handled()
        return true
    return false

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

func set_long_press_delay(_newDelay: float) -> void:
    for nextActionKey: StringName in forwardOnLongPress.keys():
        forwardOnLongPress[nextActionKey].timer.wait_time = _newDelay

func new_long_press_action(_sourceAction: StringName, _forwardedAction: StringName) -> Dictionary:
    var timeoutTimer = Timer.new()
    timeoutTimer.wait_time = GameSettings.LongPressDelay
    timeoutTimer.one_shot = true
    timeoutTimer.autostart = false
    timeoutTimer.timeout.connect(on_long_press_timeout.bind(_sourceAction, _forwardedAction))
    add_child(timeoutTimer)
    return {
        action = _forwardedAction,
        timer = timeoutTimer,
        timerFinished = false
    }
