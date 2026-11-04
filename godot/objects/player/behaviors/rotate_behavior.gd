class_name RotateBehavior
extends PlayerBehavior

## nonstandard units. 1 rotation = 50k
var rotationDelta: float

func reinit() -> void:
    rotationDelta = 0.0

func can_act() -> bool: 
    return !active && pb.grab.active

func start_action() -> void:
    if active: return
    active = true
    rotationDelta = 0.0
    pb.grab.grabbedRef.on_rotate_start()

func process_action(_delta: float) -> void:
    if (active && pb.grab.active):
        var nextAngularVelocity: Vector3 = (-p.camera.global_basis.y*p.lookDir.x + p.camera.global_basis.x * p.lookDir.y) * GameSettings.CameraSensitivity * p.ROTATION_SENSITIVITY_MULTIPLIER
        rotationDelta += nextAngularVelocity.length_squared()
        #grows fast, we only care about the first full rotation at ~50k
        if rotationDelta > 100000.0: rotationDelta = 50000.0
        pb.grab.grabbedRef.angular_velocity = nextAngularVelocity

func stop_action() -> void:
    if !active: return
    active = false
    p.lookDir = Vector2.ZERO
    pb.grab.grabbedRef.angular_velocity = Vector3.ZERO
    pb.grab.grabbedRef.on_rotate_stop()
