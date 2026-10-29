class_name FlashlightBehavior
extends PlayerBehavior

var light: SpotLight3D
var offset: Vector3 = Vector3.ZERO

func player_ready() -> void:
    light = p.get_node("Camera/Flashlight")
    offset = light.position

func reinit() -> void:
    active = false
    if light != null:
        light.visible = false
        light.position = offset

func start_action() -> void:
    if active: return
    active = true
    light.visible = true

func stop_action() -> void:
    if !active: return
    active = false
    light.visible = false
