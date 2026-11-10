class_name RotateBehavior
extends PlayerBehavior

var keepUpright: bool
## nonstandard units. 1 rotation = ~35k
var rotationDelta: float
var rotatedInitialInertia: Vector3
var lastPlayerZ: Vector3

func reinit() -> void:
    keepUpright = false
    rotationDelta = 0.0
    lastPlayerZ = -p.global_basis.z

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
    if pb.grab.active:
        var nextTorque: Vector3 = Vector3.ZERO
        if keepUpright:
            # if keepUpright, rotate object so its local y matches global y, then constrain rotation to the y axis no matter which direction camera is facing
            var grabbedBasis: Basis = pb.grab.grabbedRef.global_basis
            nextTorque += grabbedBasis.y.cross(Vector3.UP) * GameSettings.PropRotationSpeed * 10.0
            # instead of rotating in camera space, constrain rotation to y axis and only use lookDir.x magnitude
            if active:
                nextTorque += Vector3.DOWN * p.lookDir.x * GameSettings.PropRotationSpeed
        elif active:
            nextTorque += (-p.camera.global_basis.y*p.lookDir.x + p.camera.global_basis.x * p.lookDir.y) * GameSettings.PropRotationSpeed
        var nextTorqueLenSq = nextTorque.length_squared()
        rotationDelta += nextTorqueLenSq
        #grows fast, we only care about the first full rotation at ~35k
        if rotationDelta > 70000.0: rotationDelta = 35000.0
        if nextTorqueLenSq > 0.1:
            pb.grab.grabbedRef.apply_torque(nextTorque)
    lastPlayerZ = -p.global_basis.z

func stop_action() -> void:
    if !active || !pb.grab.active: return
    active = false
    p.lookDir = Vector2.ZERO
    pb.grab.grabbedRef.angular_velocity = Vector3.ZERO
    pb.grab.grabbedRef.inertia = rotatedInitialInertia
    pb.grab.grabbedRef.on_rotate_stop()
