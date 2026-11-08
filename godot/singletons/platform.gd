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
            os = Const.OperatingSystem.WINDOWS
        "Linux":
            os = Const.OperatingSystem.LINUX
        "macOS":
            os = Const.OperatingSystem.MAC
        "Android":
            os = Const.OperatingSystem.ANDROID
        "iOS":
            os = Const.OperatingSystem.IOS
        _:
            push_error("Somehow you are running on an unsupported platform. Expect major issues")
    # load optional 3rd party APIs. all are mutually-exclusive. If none are found, game is running native
    # check mobile first as they don't have cross-platform APIs
    if os == Const.OperatingSystem.ANDROID:
        # TODO Google Play and FDroid custom logic
        platform = Const.SupportedPlatform.NATIVE
    elif os == Const.OperatingSystem.IOS:
        # TODO Apple App Store custom logic
        platform = Const.SupportedPlatform.NATIVE
    else:
        if try_init_steam():
            print("Steam integration loaded")
            platform = Const.SupportedPlatform.STEAM
        else:
            platform = Const.SupportedPlatform.NATIVE
    print("Game version " + str(Const.GAME_VERSION) + " running on " + OS.get_name())

func _process(_delta: float) -> void:
    if steamEnabled: steamApi.run_callbacks()

func try_init_steam() -> bool:
    if !Engine.has_singleton("Steam"): return false
    # try to init steam. should fail and return false if the user doesn't have steam or it isn't running or they aren't logged in
    steamApi = Engine.get_singleton("Steam")
    var initResult: Dictionary = steamApi.steamInitEx(480, false)
    if initResult['status'] > steamApi.STEAM_API_INIT_RESULT_OK:
        push_warning("Steam failed to init, running in native mode: ", initResult)
        steamApi = null
        return false
    
    # TODO finish setting up steam
    # track steam inputs, then fire the events into the godot Input system via a virtual 'steam device'
    # set up the input map to know about the steam inputs firing via that virtual device.
    # Global toggle to ignore steam inputs altogether and use in-game controller settings
    # let the player choose their glyph set, defer to godot, or defer to steam
    # if a controller input is detected by godot but not by steam, switch handling methods
    # track lastInputDevice and assume that's what the player is using.
    return true
