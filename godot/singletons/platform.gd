extends Node

var os: Const.OperatingSystem
var platform: Const.SupportedPlatform

var steamApi: Object

var steamEnabled: bool:
    get: return platform == Const.SupportedPlatform.STEAM && steamApi != null

func _init() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    steamApi = null
    # determine operating system
    match OS.get_name():
        "Windows":
            init_windows()
        "Linux":
            init_linux()
        "macOS":
            init_mac()
        "Android":
            init_android()
        "iOS":
            init_ios()
        _:
            push_error("You are running on a platform not officially supported. Expect major issues")
    print("Game version " + str(Const.GAME_VERSION) + " running on " + OS.get_name())

func init_windows() -> void:
    os = Const.OperatingSystem.WINDOWS
    init_desktop()

func init_linux() -> void:
    os = Const.OperatingSystem.LINUX
    init_desktop()

func init_mac() -> void:
    os = Const.OperatingSystem.MAC
    init_desktop()

func init_desktop() -> void:
    if try_init_steam():
        print("Steam integration loaded")
        platform = Const.SupportedPlatform.STEAM
    else:
        platform = Const.SupportedPlatform.NATIVE

func init_android() -> void:
    os = Const.OperatingSystem.ANDROID
    # TODO Google Play and FDroid custom logic
    init_mobile()

func init_ios() -> void:
    os = Const.OperatingSystem.IOS
    # TODO Apple App Store custom logic
    init_mobile()

func init_mobile() -> void:
    # placeholder for now. replace with respective app store
    platform = Const.SupportedPlatform.NATIVE

func _process(_delta: float) -> void:
    if steamEnabled: steamApi.run_callbacks()

## optional steam integration
func try_init_steam() -> bool:
    if !Engine.has_singleton("Steam"): return false
    # try to init steam. should fail and return false if the user doesn't have steam or it isn't running or they aren't logged in
    steamApi = Engine.get_singleton("Steam")
    var initResult: Dictionary = steamApi.steamInitEx(480, false)
    if initResult['status'] > steamApi.STEAM_API_INIT_RESULT_OK:
        push_warning("Steam failed to init, running in native mode: ", initResult)
        steamApi = null 
        return false
    # TODO finish setting up steam, likely in a sub-script cause there's a lot
    # read here: https://godotsteam.com/tutorials/initializing/#extra-tools
    # good example here: https://codeberg.org/godotsteam/skillet/src/branch/demo/src/autoload/steamworks.gd
    # track steam inputs, then fire the events into the godot Input system via a virtual 'steam device' (negative ID)
    # steam input docs: https://godotsteam.com/tutorials/inputs/#is_action_pressed
    # input event docs: https://docs.godotengine.org/en/stable/tutorials/inputs/inputevent.html
    # Global toggle to ignore steam inputs altogether and use in-game controller settings
    # let the player choose their glyph set, defer to godot, or defer to steam
    # if a controller input is detected by godot but not by steam, switch handling methods
    # track lastInputDevice and assume that's what the player is using for prompts
    # all connected devices remain usable simultaneously
    return true
