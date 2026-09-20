extends Node
class_name MenuManager

var mainMenu: MainMenu
var settingsMenu: SettingsMenu
var saveSelectMenu: SaveSelectMenu
var pauseMenu: PauseMenu
var hudMenu: HUDMenu

func _init(
    _main: MainMenu,
    _settings: SettingsMenu,
    _saveSelect: SaveSelectMenu,
    _pause: PauseMenu,
    _hud: HUDMenu
):
    mainMenu = _main
    settingsMenu = _settings
    saveSelectMenu = _saveSelect
    pauseMenu = _pause
    hudMenu = _hud
    SignalBus.goto_previous_menu.connect(on_goto_previous_menu)
    SignalBus.goto_main_menu.connect(on_goto_main_menu)
    SignalBus.goto_settings_menu.connect(on_goto_settings_menu)
    SignalBus.goto_save_select_menu.connect(on_goto_save_select_menu)
    SignalBus.goto_pause_menu.connect(on_goto_pause_menu)
    SignalBus.goto_hud_menu.connect(on_goto_hud_menu)

func on_goto_previous_menu(previousMenuName: Enum.MenuType):
    match previousMenuName:
        Enum.MenuType.MAIN:
            on_goto_main_menu()
        Enum.MenuType.PAUSE:
            on_goto_pause_menu()
        Enum.MenuType.SETTINGS:
            on_goto_settings_menu(previousMenuName)
        Enum.MenuType.SAVE_SELECT:
            on_goto_save_select_menu(previousMenuName)

func on_goto_main_menu() -> void:
    settingsMenu.process_mode = Node.PROCESS_MODE_DISABLED
    saveSelectMenu.process_mode = Node.PROCESS_MODE_DISABLED
    pauseMenu.process_mode = Node.PROCESS_MODE_DISABLED
    hudMenu.process_mode = Node.PROCESS_MODE_DISABLED
    settingsMenu.hide()
    saveSelectMenu.hide()
    pauseMenu.hide()
    hudMenu.hide()
    
    mainMenu.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
    mainMenu.show()

func on_goto_settings_menu(previousMenuName: Enum.MenuType) -> void:
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
    hudMenu.process_mode = Node.PROCESS_MODE_DISABLED
    mainMenu.hide()
    settingsMenu.hide()
    hudMenu.hide()
    
    pauseMenu.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
    pauseMenu.show()

func on_goto_save_select_menu(_previousMenuName: Enum.MenuType) -> void:
    mainMenu.process_mode = Node.PROCESS_MODE_DISABLED
    pauseMenu.process_mode = Node.PROCESS_MODE_DISABLED
    mainMenu.hide()
    pauseMenu.hide()
    
    saveSelectMenu.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
    saveSelectMenu.show()

func on_goto_hud_menu() -> void:
    mainMenu.process_mode = Node.PROCESS_MODE_DISABLED
    settingsMenu.process_mode = Node.PROCESS_MODE_DISABLED
    saveSelectMenu.process_mode = Node.PROCESS_MODE_DISABLED
    pauseMenu.process_mode = Node.PROCESS_MODE_DISABLED
    mainMenu.hide()
    settingsMenu.hide()
    saveSelectMenu.hide()
    pauseMenu.hide()
    
    hudMenu.process_mode = Node.PROCESS_MODE_PAUSABLE
    hudMenu.show()
