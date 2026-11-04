extends CanvasLayer
class_name SettingsMenu

@onready var cancelButton: Button = $CenterContainer/VBoxContainer/SettingsTopControlsHBox/CancelButton
@onready var saveAndReturnButton: Button = $CenterContainer/VBoxContainer/SettingsTopControlsHBox/SaveAndReturnButton
@onready var cameraSensitivityValue: Label = $CenterContainer/VBoxContainer/CameraSensitivityHBox/CameraSensitivityValue
@onready var cameraSensitivitySlider: HSlider = $CenterContainer/VBoxContainer/CameraSensitivityHBox/CameraSensitivityHSlider
@onready var resetCameraSensitivityButton: TextureButton = $CenterContainer/VBoxContainer/CameraSensitivityHBox/ResetCameraSensitivityButton
@onready var longPressDelayValue: Label = $CenterContainer/VBoxContainer/LongPressDelayHBox/LongPressDelayValue
@onready var longPressDelayHSlider: HSlider = $CenterContainer/VBoxContainer/LongPressDelayHBox/LongPressDelayHSlider
@onready var resetLongPressDelayButton: TextureButton = $CenterContainer/VBoxContainer/LongPressDelayHBox/LongPressDelayButton
@onready var undoChangesButton: Button = $CenterContainer/VBoxContainer/SettingsBottomControlsHBox/UndoChangesButton
@onready var loadDefaultsButton: Button = $CenterContainer/VBoxContainer/SettingsBottomControlsHBox/LoadDefaultsButton
@onready var saveButton: Button = $CenterContainer/VBoxContainer/SettingsBottomControlsHBox/SaveButton

var previousMenu: Const.MenuType

func _ready() -> void:
    cancelButton.button_up.connect(on_cancel_pressed)
    saveAndReturnButton.button_up.connect(on_save_and_return_pressed)
    cameraSensitivitySlider.value_changed.connect(on_camera_sensitivity_slider_changed)
    resetCameraSensitivityButton.button_up.connect(on_camera_sensitivity_reset_pressed)
    longPressDelayHSlider.value_changed.connect(on_long_press_delay_slider_changed)
    resetLongPressDelayButton.button_up.connect(on_long_press_delay_reset_pressed)
    undoChangesButton.button_up.connect(on_undo_changes_pressed)
    loadDefaultsButton.button_up.connect(on_load_defaults_pressed)
    saveButton.button_up.connect(on_save_pressed)
    load_settings_into_controls()

func load_settings_into_controls():
    cameraSensitivityValue.text = str(GameSettings.CameraSensitivity)
    cameraSensitivitySlider.value = GameSettings.CameraSensitivity
    longPressDelayValue.text = str(GameSettings.LongPressDelay)
    longPressDelayHSlider.value = GameSettings.LongPressDelay

func on_cancel_pressed():
    SignalBus.goto_previous_menu.emit(previousMenu)

func on_save_and_return_pressed():
    on_save_pressed()
    SignalBus.goto_previous_menu.emit(previousMenu)

func on_camera_sensitivity_slider_changed(valueChanged: bool):
    if !valueChanged: return
    cameraSensitivityValue.text = str(cameraSensitivitySlider.value)
    show_hide_camera_sensitivity_reset()
    if cameraSensitivitySlider.value != GameSettings.CameraSensitivity:
        mark_pending_changes()

func on_camera_sensitivity_reset_pressed():
    cameraSensitivitySlider.value = GameSettings.defaults.General.CameraSensitivity
    resetCameraSensitivityButton.hide()
    mark_pending_changes()

func show_hide_camera_sensitivity_reset():
    if GameSettings.CameraSensitivity == GameSettings.defaults.General.CameraSensitivity:
        resetCameraSensitivityButton.hide()
    else:
        resetCameraSensitivityButton.show()

func on_long_press_delay_slider_changed(valueChanged: bool):
    if !valueChanged: return
    longPressDelayValue.text = str(longPressDelayHSlider.value)
    show_hide_long_press_delay_reset()
    if longPressDelayHSlider.value != GameSettings.LongPressDelay:
        mark_pending_changes()

func on_long_press_delay_reset_pressed():
    longPressDelayHSlider.value = GameSettings.defaults.General.LongPressDelay
    resetLongPressDelayButton.hide()
    mark_pending_changes()

func show_hide_long_press_delay_reset():
    if Utils.equalsf(GameSettings.LongPressDelay, GameSettings.defaults.General.LongPressDelay):
        resetLongPressDelayButton.hide()
    else:
        resetLongPressDelayButton.show()

func on_undo_changes_pressed():
    GameSettings.load_from_disk()
    load_settings_into_controls()
    clear_pending_changes()

func on_load_defaults_pressed():
    GameSettings.write_default_settings()
    load_settings_into_controls()
    mark_pending_changes()

func on_save_pressed():
    if GameSettings.CameraSensitivity != cameraSensitivitySlider.value:
        # apply camera sensitivity
        GameSettings.CameraSensitivity = cameraSensitivitySlider.value
        show_hide_camera_sensitivity_reset()
        # apply long press delay
        GameSettings.LongPressDelay = longPressDelayHSlider.value
        if State.player != null:
            State.player.set_long_press_delay(GameSettings.LongPressDelay)
        show_hide_long_press_delay_reset()
    GameSettings.save_to_disk()
    clear_pending_changes()

func mark_pending_changes():
    if saveButton.text != "Save*":
        saveButton.text = "Save*"
        saveAndReturnButton.show()
        saveButton.disabled = false

func clear_pending_changes():
    if saveButton.text != "Save":
        saveButton.text = "Save"
        saveAndReturnButton.hide()
        saveButton.disabled = true

func _unhandled_key_input(event: InputEvent) -> void:
    var eventHandled = false
    if (visible && event.is_action_pressed("ui_close_dialog")):
        SignalBus.goto_previous_menu.emit(previousMenu)
        eventHandled = true
    if (eventHandled):
        get_tree().root.set_input_as_handled()
