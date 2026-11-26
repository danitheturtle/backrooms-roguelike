class_name RadialMenu
extends Control

@export var radialSelectorMaterial: ShaderMaterial
## multiplied by UI_SCALE
@export var radiusUnits: float = 8.0

var radius: float:
    get: return radiusUnits * GameSettings.UIScale
var diameter: float:
    get: return radius * 2.0
var innerRadius: float:
    get: return selectorRing.material["shader_parameter/inner_radius"] * diameter
var buttonCount: int:
    get: return 0 if buttons == null else buttons.size()

## active
var active: bool = false
## normalized vector on unit circle pointing in selected direction. If length is less than one, cursor is inside deadzone
var cursor: Vector2
## buttons on the radial menu wheel
var buttons: Array[BaseButton]

var selectorRing: ColorRect

func _ready() -> void:
    create_selector_shader_rect()
    cursor = Vector2.ZERO
    for nextButton in Utils.get_children_of_type(self, BaseButton) as Array[BaseButton]:
        if nextButton is BaseButton: buttons.append(nextButton)
    arrange_buttons()
    active = false

func _input(_event: InputEvent) -> void:
    if !active: return

func open() -> void:
    active = true

func close() -> void:
    active = false

func arrange_buttons() -> void:
    if buttonCount == 0: return
    var angleIncrement: float = TAU / buttonCount
    var angle: float = 0
    # midpoint radius of the selectorRing ring
    var buttonCenterRadius: float = radius - (radius - innerRadius) * 0.5
    for nextButton: BaseButton in buttons:
        nextButton.position = Vector2.from_angle(angle) * buttonCenterRadius - nextButton.size * 0.5
        angle += angleIncrement

func create_selector_shader_rect() -> void:
    selectorRing = ColorRect.new()
    selectorRing.size = Vector2(radius,radius) * 2.0
    selectorRing.position = -Vector2(radius,radius)
    selectorRing.material = radialSelectorMaterial
    add_child(selectorRing)
    move_child(selectorRing,0)
