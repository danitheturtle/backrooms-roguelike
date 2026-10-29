class_name RotateBehavior
extends PlayerBehavior

func can_act() -> bool: 
    return p.b.grab.active && p.heldObjectRef != null

func start_action() -> void:
    if active: return
    active = true
    p.heldObjectRef.on_rotate_start()

func process_action(_delta: float) -> void:
    p.heldObjectRef.angular_velocity = (-p.camera.global_basis.y*p.cameraMoveDir.x + p.camera.global_basis.x * p.cameraMoveDir.y) * GameSettings.CameraSensitivity * 100.0
