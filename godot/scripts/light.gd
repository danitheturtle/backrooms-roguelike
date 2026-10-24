@tool
extends Node3D
class_name Light

@export var onMaterial: BaseMaterial3D = null
@export var offMaterial: BaseMaterial3D = null

@export var primaryEnabled: bool = true: set = set_primary_enabled
@export var bounceEnabled: bool = true: set = set_bounce_enabled
@export var randomDynamics: bool = false: set = set_random_dynamics
@export_color_no_alpha var lightColor: Color = Color.from_ok_hsl(0.3,0.89,0.92,1.0): set = set_light_color
@export_color_no_alpha var bounceColor: Color = Color.from_ok_hsl(0.2889,0.89,0.92): set = set_bounce_color
@export_range(0.1, 10.0, 0.1) var intensity: float = 4.0: set = set_intensity
@export var lightOn: bool = true: set = set_light_on

@onready var lightMesh: MeshInstance3D = $Mesh
var primary: Light3D = null
var bounce: Light3D = null
var lessIntenseEmissionMaterial: BaseMaterial3D

func _ready() -> void:
    primary = $Primary
    if primary == null: primaryEnabled = false
    bounce = $Bounce
    if bounce == null: bounceEnabled = false
    set_primary_enabled(primaryEnabled)
    set_bounce_enabled(bounceEnabled)
    set_random_dynamics(randomDynamics)
    set_light_color(lightColor)
    set_bounce_color(bounceColor)
    set_light_on(lightOn)
    set_intensity(intensity)
    if !Engine.is_editor_hint():
        if !primaryEnabled: primary.queue_free()
        if !bounceEnabled: bounce.queue_free()

func set_light_on(newValue: bool) -> void:
    lightOn = newValue
    if lightMesh == null: return
    if newValue:
        lightMesh.material_override = onMaterial
    else:
        lightMesh.material_override = offMaterial
    if primaryEnabled && primary != null:
        if newValue:
            primary.show()
        else:
            primary.hide()
    if bounceEnabled && bounce != null:
        if newValue:
            bounce.show()
        else:
            bounce.hide()

func set_light_color(newValue: Color) -> void:
    var oldLightColor = lightColor
    lightColor = newValue
    if primaryEnabled && primary != null:
        primary.light_color = newValue
    if bounceColor == Color.WHITE or bounceColor == oldLightColor:
        set_bounce_color(newValue)

func set_bounce_color(newValue: Color) -> void:
    bounceColor = newValue
    if bounceEnabled && bounce != null:
        bounce.light_color = newValue

func set_primary_enabled(newValue: bool) -> void:
    if primary == null: 
        primaryEnabled = false
        return
    primaryEnabled = newValue
    if newValue:
        if lightOn: primary.show()
        primary.process_mode = Node.PROCESS_MODE_INHERIT
    else:
        primary.hide()
        primary.process_mode = Node.PROCESS_MODE_DISABLED

func set_bounce_enabled(newValue: bool) -> void:
    if bounce == null:
        bounceEnabled = false
        return
    bounceEnabled = newValue
    if newValue:
        if lightOn: bounce.show()
        primary.process_mode = Node.PROCESS_MODE_INHERIT
    else:
        bounce.hide()
        primary.process_mode = Node.PROCESS_MODE_DISABLED

func set_intensity(newValue: float) -> void:
    intensity = newValue
    if primary == null: return
    if bounce == null: return
    primary.light_energy = newValue
    bounce.light_energy = maxf(newValue / 8.0, 0.05)
    if newValue < 3.0:
        if lessIntenseEmissionMaterial == null:
            lessIntenseEmissionMaterial = onMaterial.duplicate()
        lessIntenseEmissionMaterial.emission_energy_multiplier = minf(1.0, newValue / 4.0)
        lightMesh.material_override = lessIntenseEmissionMaterial
    else:
        lightMesh.material_override = onMaterial

func set_random_dynamics(newValue: bool) -> void:
    randomDynamics = newValue
