class_name RotateBehavior
extends PlayerBehavior

const SENSITIVITY_MULTIPLIER: float = 100.0

## nonstandard units. 1 rotation = 50k
var rotationDelta: float

func reinit() -> void:
    rotationDelta = 0.0

func can_act() -> bool: 
    return !active && pb.grab.active && p.heldObjectRef != null

func start_action() -> void:
    if active: return
    active = true
    rotationDelta = 0.0
    p.heldObjectRef.on_rotate_start()

func process_action(_delta: float) -> void:
    if (active && pb.grab.active && p.heldObjectRef != null):
        var nextAngularVelocity: Vector3 = (-p.camera.global_basis.y*p.cameraMoveDir.x + p.camera.global_basis.x * p.cameraMoveDir.y) * GameSettings.CameraSensitivity * SENSITIVITY_MULTIPLIER
        rotationDelta += nextAngularVelocity.length_squared()
        #grows fast, we only care about the first full rotation at ~50k
        if rotationDelta > 100000.0: rotationDelta = 50000.0
        p.heldObjectRef.angular_velocity = nextAngularVelocity

func stop_action() -> void:
    if !active: return
    active = false
    p.heldObjectRef.on_rotate_stop()
