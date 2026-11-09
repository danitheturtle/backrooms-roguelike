extends CanvasLayer
class_name SettingsMenu

@export var cancelBackButton: Button
@export var saveAndReturnButton: Button
@export var cameraSensitivityValue: Label
@export var cameraSensitivitySlider: HSlider
@export var resetCameraSensitivityButton: TextureButton
@export var propRotationSpeedValue: Label
@export var propRotationSpeedSlider: HSlider
@export var resetPropRotationSpeedButton: TextureButton
@export var longPressDelayValue: Label
@export var longPressDelaySlider: HSlider
@export var resetLongPressDelayButton: TextureButton
@export var undoChangesButton: Button
@export var loadDefaultsButton: Button
@export var saveButton: Button

var previousMenu: Const.MenuType

func _ready() -> void:
    cancelBackButton.button_up.connect(on_cancel_back_pressed)
    saveAndReturnButton.button_up.connect(on_save_and_return_pressed)
    cameraSensitivitySlider.value_changed.connect(on_camera_sensitivity_slider_changed)
    resetCameraSensitivityButton.button_up.connect(on_camera_sensitivity_reset_pressed)
    propRotationSpeedSlider.value_changed.connect(on_prop_rotation_speed_slider_changed)
    resetPropRotationSpeedButton.button_up.connect(on_prop_rotation_speed_reset_pressed)
    longPressDelaySlider.value_changed.connect(on_long_press_delay_slider_changed)
    resetLongPressDelayButton.button_up.connect(on_long_press_delay_reset_pressed)
    undoChangesButton.button_up.connect(on_undo_changes_pressed)
    loadDefaultsButton.button_up.connect(on_load_defaults_pressed)
    saveButton.button_up.connect(on_save_pressed)
    load_settings_into_controls()

func load_settings_into_controls():
    cameraSensitivityValue.text = str(GameSettings.CameraSensitivity)
    cameraSensitivitySlider.value = GameSettings.CameraSensitivity
    propRotationSpeedValue.text = str(GameSettings.PropRotationSpeed)
    propRotationSpeedSlider.value = GameSettings.PropRotationSpeed
    longPressDelayValue.text = str(GameSettings.LongPressDelay)
    longPressDelaySlider.value = GameSettings.LongPressDelay

func on_cancel_back_pressed():
    clear_pending_changes()
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

func on_prop_rotation_speed_slider_changed(valueChanged: bool):
    if !valueChanged: return
    propRotationSpeedValue.text = str(propRotationSpeedSlider.value)
    show_hide_prop_rotation_speed_reset()
    if propRotationSpeedSlider.value != GameSettings.PropRotationSpeed:
        mark_pending_changes()

func on_prop_rotation_speed_reset_pressed():
    propRotationSpeedSlider.value = GameSettings.defaults.General.PropRotationSpeed
    resetPropRotationSpeedButton.hide()
    mark_pending_changes()

func show_hide_prop_rotation_speed_reset():
    if GameSettings.PropRotationSpeed == GameSettings.defaults.General.PropRotationSpeed:
        resetPropRotationSpeedButton.hide()
    else:
        resetPropRotationSpeedButton.show()

func on_long_press_delay_slider_changed(valueChanged: bool):
    if !valueChanged: return
    longPressDelayValue.text = str(longPressDelaySlider.value)
    show_hide_long_press_delay_reset()
    if longPressDelaySlider.value != GameSettings.LongPressDelay:
        mark_pending_changes()

func on_long_press_delay_reset_pressed():
    longPressDelaySlider.value = GameSettings.defaults.General.LongPressDelay
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
    #apply settings
    if GameSettings.CameraSensitivity != cameraSensitivitySlider.value:
        GameSettings.CameraSensitivity = cameraSensitivitySlider.value
        show_hide_camera_sensitivity_reset()
    if GameSettings.PropRotationSpeed != propRotationSpeedSlider.value:
        GameSettings.PropRotationSpeed = propRotationSpeedSlider.value
        show_hide_prop_rotation_speed_reset()
    if GameSettings.LongPressDelay != longPressDelaySlider.value:
        GameSettings.LongPressDelay = longPressDelaySlider.value
        InputManager.set_long_press_delay(GameSettings.LongPressDelay)
        if State.player != null:
            State.player.set_long_press_delay(GameSettings.LongPressDelay)
        show_hide_long_press_delay_reset()
    GameSettings.save_to_disk()
    clear_pending_changes()

func mark_pending_changes():
    if cancelBackButton.text != "Cancel":
        cancelBackButton.text = "Cancel"
    if saveButton.text != "Save*":
        saveButton.text = "Save*"
        saveAndReturnButton.show()
        saveButton.disabled = false

func clear_pending_changes():
    if cancelBackButton.text != "Back":
        cancelBackButton.text = "Back"
    if saveButton.text != "Save":
        saveButton.text = "Save"
        saveAndReturnButton.hide()
        saveButton.disabled = true

func _unhandled_key_input(event: InputEvent) -> void:
    var eventHandled = false
    if (visible && event.is_action_pressed("ui_close_dialog")):
        on_cancel_back_pressed()
        eventHandled = true
    if (eventHandled):
        get_tree().root.set_input_as_handled()
