class_name RadialMenu
extends Control

@export var selectorRing: ColorRect
## multiplied by UI_SCALE
@export var radiusUnits: float = 8.0:
    set(newRadiusUnits):
        radiusUnits = newRadiusUnits
        if selectorRing != null:
            selectorRing.size = Vector2(newRadiusUnits,newRadiusUnits) * 2.0 * GameSettings.UIScale
            selectorRing.position = -Vector2(newRadiusUnits,newRadiusUnits) * GameSettings.UIScale

var radius: float:
    get: return radiusUnits * GameSettings.UIScale
var diameter: float:
    get: return radius * 2.0
var buttonCount: int:
    get: return 0 if buttons == null else buttons.size()

# shader getter / setters
var innerRadius: float:
    get: return selectorRing.material["shader_parameter/inner_radius"] * diameter
var cursorEnabled: bool:
    get: return selectorRing.material["shader_parameter/cursor_enabled"]
    set(newCursorEnabled): selectorRing.material["shader_parameter/cursor_enabled"] = newCursorEnabled
var cursorPos: float:
    get: return selectorRing.material["shader_parameter/cursor_pos"]
    set(newCursorPos): selectorRing.material["shader_parameter/cursor_pos"] = newCursorPos
var cursorSize: float:
    get: return selectorRing.material["shader_parameter/cursor_size"]
    set(newCursorSize): selectorRing.material["shader_parameter/cursor_size"] = newCursorSize

## buttons on the radial menu wheel
var buttons: Array[BaseButton]
## deadzone at the center of the menu from 0.0-1.0
var deadzone: float = 0.5
## normalized vector on unit circle pointing in selected direction
var cursor: Vector2

func _init() -> void:
    hide()

func _ready() -> void:
    cursor = Vector2.ZERO
    radiusUnits = radiusUnits
    for nextButton in Utils.get_children_of_type(self, BaseButton):
        if nextButton is BaseButton: buttons.append(nextButton)
    arrange_buttons()

func _input(_event: InputEvent) -> void:
    if _event.is_action_pressed(&"action_wheel"):
        show()
        get_tree().root.set_input_as_handled()
    if !visible: return
    var eventHandled = false
    if _event is InputEventMouseMotion:
        if InputManager.mouseCaptured:
            SignalBus.release_mouse.emit()
        cursor = (_event.global_position - global_position).limit_length(innerRadius) / innerRadius
        cursorEnabled = cursor.length_squared() > deadzone * deadzone
        cursorPos = Vector2.RIGHT.angle_to(cursor)
        eventHandled = true
    elif _event.is_action_released(&"action_wheel"):
        # select the hovered button and fire event
        if !InputManager.mouseCaptured:
            SignalBus.capture_mouse.emit()
        hide()
        eventHandled = true
    if eventHandled:
        get_tree().root.set_input_as_handled()

func arrange_buttons() -> void:
    if buttonCount == 0: return
    var angleIncrement: float = TAU / buttonCount
    cursorSize = angleIncrement
    var angle: float = 0
    # midpoint radius of the selectorRing ring
    var buttonCenterRadius: float = radius - (radius - innerRadius) * 0.5
    for nextButton: BaseButton in buttons:
        nextButton.position = Vector2.from_angle(angle) * buttonCenterRadius - nextButton.size * 0.5
        angle += angleIncrement
