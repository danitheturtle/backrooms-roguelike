class_name ThrowBehavior
extends PlayerBehavior

var unhandledInput: bool

func reinit() -> void:
    unhandledInput = false

func can_act() -> bool:
    return pb.grab.active

func start_action() -> void:
    if !unhandledInput: return
    var velocityInCameraDir: Vector3 = (-p.camera.global_basis.z * pb.grab.grabbedRef.throwImpulse)
    var lobVelocity: Vector3 = Vector3(0.0, pb.grab.grabbedRef.throwLobFactor, 0.0)
    pb.grab.grabbedRef.linear_velocity = velocityInCameraDir + lobVelocity
    pb.grab.grabbedRef.on_throw()
    unhandledInput = false
    pb.grab.stop_action()

func process_action(_delta: float) -> void:
    if pb.throw.can_act() && unhandledInput:
        pb.throw.start_action()
