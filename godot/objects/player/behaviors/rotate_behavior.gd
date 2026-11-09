class_name RotateBehavior
extends PlayerBehavior

## nonstandard units. 1 rotation = ~35k
var rotationDelta: float
var rotatedInitialInertia: Vector3

func reinit() -> void:
    rotationDelta = 0.0

func can_act() -> bool: 
    return !active && pb.grab.active

func start_action() -> void:
    if active || !pb.grab.active: return
    active = true
    rotationDelta = 0.0
    rotatedInitialInertia = pb.grab.grabbedRef.inertia
    pb.grab.grabbedRef.inertia = p.ROTATED_INERTIA
    pb.grab.grabbedRef.on_rotate_start()

func process_action(_delta: float) -> void:
    if (active && pb.grab.active):
        var nextAngularVelocity: Vector3 = (-p.camera.global_basis.y*p.lookDir.x + p.camera.global_basis.x * p.lookDir.y) * GameSettings.PropRotationSpeed
        rotationDelta += nextAngularVelocity.length_squared()
        #grows fast, we only care about the first full rotation at ~35k
        if rotationDelta > 70000.0: rotationDelta = 35000.0
        pb.grab.grabbedRef.apply_torque(nextAngularVelocity)

func stop_action() -> void:
    if !active || !pb.grab.active: return
    active = false
    p.lookDir = Vector2.ZERO
    pb.grab.grabbedRef.angular_velocity = Vector3.ZERO
    pb.grab.grabbedRef.inertia = rotatedInitialInertia
    pb.grab.grabbedRef.on_rotate_stop()
