@tool
extends Node3D
class_name Light

@export var onMaterial: BaseMaterial3D = null
@export var offMaterial: BaseMaterial3D = null

@export var primaryEnabled: bool = true: set = set_primary_enabled
@export var bounceEnabled: bool = true: set = set_bounce_enabled
@export var randomDynamics: bool = false: set = set_random_dynamics

@export var lightOn: bool = true: set = set_light_on

@onready var lightMesh: MeshInstance3D = $Mesh
var primary: Light3D = null
var bounce: Light3D = null

func _ready() -> void:
    primary = $Primary
    if primary == null: primaryEnabled = false
    bounce = $Bounce
    if bounce == null: bounceEnabled = false
    set_primary_enabled(primaryEnabled)
    set_bounce_enabled(bounceEnabled)
    set_random_dynamics(randomDynamics)
    set_light_on(lightOn)
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

func set_random_dynamics(newValue: bool) -> void:
    randomDynamics = newValue
