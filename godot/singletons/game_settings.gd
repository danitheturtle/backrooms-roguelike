extends Node

const defaults = {
    "General": {
        "Initialized": false,
        "CameraSensitivity": 0.1,
        "UIScale": 16,
        "LongPressDelay": 0.5
    }
}

var settings := ConfigFile.new()

var CameraSensitivity: float:
    set(newSensitivity):
        settings.set_value("General", "CameraSensitivity", newSensitivity)
    get:
        return settings.get_value("General", "CameraSensitivity", defaults.General.CameraSensitivity)

var UIScale: int:
    set(newScale):
        settings.set_value("General", "UIScale", newScale)
    get:
        return settings.get_value("General", "UIScale", defaults.General.UIScale)

var LongPressDelay: float:
    set(newDelay):
        settings.set_value("General", "LongPressDelay", newDelay)
    get:
        return settings.get_value("General", "LongPressDelay", defaults.General.LongPressDelay)

func _init() -> void:
    # load config or create it if it doesn't exist
    var loadError = Utils.load_or_create_config(settings, "user://game_settings.ini")
    if loadError != OK:
        print("error creating or loading settings. likely no file acces. loading in-memory defaults", loadError)
        write_default_settings()
    if settings.get_value("General", "initialized", false):
        write_default_settings()

func write_default_settings() -> void:
    settings.set_value("General", "CameraSensitivity", defaults.General.CameraSensitivity)
    settings.set_value("General", "UIScale", defaults.General.UIScale)
    settings.set_value("General", "LongPressDelay", defaults.General.LongPressDelay)
    settings.set_value("General", "Initialized", defaults.General.Initialized)

func load_from_disk() -> void:
    var loadFromDiskResult = settings.save("user://game_settings.ini")
    if loadFromDiskResult != OK:
        print("could not load settings", loadFromDiskResult)

func save_to_disk() -> void:
    var saveToDiskResult = settings.save("user://game_settings.ini")
    if saveToDiskResult != OK:
        print("could not save settings", saveToDiskResult)
