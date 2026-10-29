class_name ThrowBehavior
extends PlayerBehavior

func start_action() -> void:
    p.heldObjectRef.linear_velocity = (-p.camera.global_basis.z * p.heldObjectRef.throwImpulse) + Vector3(0.0, p.heldObjectRef.throwLobFactor, 0.0)
    p.heldObjectRef.on_throw()
    p.throwHeldOnNextFrame = false
    pb.grab.stop_action()
