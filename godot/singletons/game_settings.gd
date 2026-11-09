extends Node

const oldestCompatibleConfigVersion: Array[int] = [0,0,2]

const defaults = {
    "General": {
        "CameraSensitivity": 0.25,
        "PropRotationSpeed": 2.0,
        "UIScale": 16,
        "KeyboardUsesLongPress": true,
        "JoypadUsesLongPress": true,
        "LongPressDelay": 0.5
    },
    "Meta": {
        "Initialized": false,
        # "GameVersion": Const.GAME_VERSION # not const; read from project settings at runtime
    }
}

var settings := ConfigFile.new()

var CameraSensitivity: float:
    set(newSensitivity):
        settings.set_value("General", "CameraSensitivity", newSensitivity)
    get:
        return settings.get_value("General", "CameraSensitivity", defaults.General.CameraSensitivity)

var PropRotationSpeed: float:
    set(newSpeed):
        settings.set_value("General", "PropRotationSpeed", newSpeed)
    get:
        return settings.get_value("General", "PropRotationSpeed", defaults.General.PropRotationSpeed)

var UIScale: int:
    set(newScale):
        settings.set_value("General", "UIScale", newScale)
    get:
        return settings.get_value("General", "UIScale", defaults.General.UIScale)

## exposing this setting to the user is a stretch goal
var KeyboardUsesLongPress: bool:
    set(newValue):
        settings.set_value("General", "KeyboardUsesLongPress", newValue)
    get:
        return settings.get_value("General", "KeyboardUsesLongPress", defaults.General.KeyboardUsesLongPress)

var JoypadUsesLongPress: bool:
    set(newValue):
        settings.set_value("General", "JoypadUsesLongPress", newValue)
    get:
        return settings.get_value("General", "JoypadUsesLongPress", defaults.General.JoypadUsesLongPress)

var LongPressDelay: float:
    set(newDelay):
        settings.set_value("General", "LongPressDelay", newDelay)
    get:
        return settings.get_value("General", "LongPressDelay", defaults.General.LongPressDelay)

func _init() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    # load config or create it if it doesn't exist
    var loadError = Utils.load_or_create_config(settings, "user://game_settings.ini")
    if loadError != OK:
        print("error creating or loading settings. likely no file acces. loading in-memory defaults", loadError)
        write_default_settings()
    if !settings.get_value("Meta", "Initialized", false):
        write_default_settings()
        save_to_disk()
    var savedGameVersion: String = settings.get_value("Meta", "GameVersion", "0.0.1")
    if !Utils.is_version_valid(oldestCompatibleConfigVersion, savedGameVersion):
        migrate_settings()

func write_default_settings() -> void:
    CameraSensitivity = defaults.General.CameraSensitivity
    PropRotationSpeed = defaults.General.PropRotationSpeed
    UIScale = defaults.General.UIScale
    KeyboardUsesLongPress = defaults.General.KeyboardUsesLongPress
    JoypadUsesLongPress = defaults.General.JoypadUsesLongPress
    LongPressDelay = defaults.General.LongPressDelay
    settings.set_value("Meta", "Initialized", true)
    settings.set_value("Meta", "GameVersion", Const.GAME_VERSION)

func migrate_settings():
    write_missing_settings_as_default()
    settings.set_value("Meta", "GameVersion", Const.GAME_VERSION)
    save_to_disk()

func write_missing_settings_as_default() -> void:
    # properties return default if setting is missing. use property assignment to ensure settings file is fully formed
    if CameraSensitivity == defaults.General.CameraSensitivity:
        CameraSensitivity = defaults.General.CameraSensitivity
    if PropRotationSpeed == defaults.General.PropRotationSpeed:
        PropRotationSpeed = defaults.General.PropRotationSpeed
    if UIScale == defaults.General.UIScale:
        UIScale = defaults.General.UIScale
    if KeyboardUsesLongPress == defaults.General.KeyboardUsesLongPress:
        KeyboardUsesLongPress = defaults.General.KeyboardUsesLongPress
    if JoypadUsesLongPress == defaults.General.JoypadUsesLongPress:
        JoypadUsesLongPress = defaults.General.JoypadUsesLongPress
    if LongPressDelay == defaults.General.LongPressDelay:
        LongPressDelay = defaults.General.LongPressDelay
    if !settings.get_value("Meta", "Initialized", false):
        settings.set_value("Meta", "Initialized", true)

func load_from_disk() -> void:
    var loadFromDiskResult = settings.save("user://game_settings.ini")
    if loadFromDiskResult != OK:
        print("could not load settings", loadFromDiskResult)

func save_to_disk() -> void:
    var saveToDiskResult = settings.save("user://game_settings.ini")
    if saveToDiskResult != OK:
        print("could not save settings", saveToDiskResult)
