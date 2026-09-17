extends Node

const defaults = {
    "General": {
        "Initialized": false,
        "CameraSensitivity": 0.1
    }
}

var settings := ConfigFile.new()

var CameraSensitivity: float:
    set(newSensitivity):
        settings.set_value("General", "CameraSensitivity", newSensitivity)
    get:
        return settings.get_value("General", "CameraSensitivity", defaults.General.CameraSensitivity)

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
    settings.set_value("General", "Initialized", defaults.General.Initialized)

func load_from_disk() -> void:
    var loadFromDiskResult = settings.save("user://game_settings.ini")
    if loadFromDiskResult != OK:
        print("could not load settings", loadFromDiskResult)

func save_to_disk() -> void:
    var saveToDiskResult = settings.save("user://game_settings.ini")
    if saveToDiskResult != OK:
        print("could not save settings", saveToDiskResult)
