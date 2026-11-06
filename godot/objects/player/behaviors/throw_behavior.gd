class_name ThrowBehavior
extends PlayerBehavior

var unhandledInput: bool

func reinit() -> void:
    unhandledInput = false

func can_act() -> bool:
    return pb.grab.active

func start_action() -> void:
    if !unhandledInput: return
    var thrownRef := pb.grab.grabbedRef
    pb.grab.stop_action()
    var velocityInCameraDir: Vector3 = (-p.camera.global_basis.z * thrownRef.throwImpulse)
    var lobVelocity: Vector3 = Vector3(0.0, thrownRef.throwLobFactor, 0.0)
    thrownRef.linear_velocity = velocityInCameraDir + lobVelocity
    thrownRef.on_throw()
    unhandledInput = false

func process_action(_delta: float) -> void:
    if pb.throw.can_act() && unhandledInput:
        pb.throw.start_action()
