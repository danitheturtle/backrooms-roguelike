class_name LookBehavior
extends PlayerBehavior

const cannotTransitionFrom: Array[StringName] = [&"rotate"]

func can_act() -> bool:
    return pb.none(cannotTransitionFrom)

func process_action(_delta: float) -> void:
    # handle camera rotation. skip if input is being used for object rotation
    if can_act():
        var cameraVelocity = -GameSettings.CameraSensitivity
        if (pb.grab.active || pb.drag.active):
            cameraVelocity *= p.SLOWED_CAMERA_DAMPING
        if (p.lookDir.y < 0 && p.camera.rotation_degrees.x < 85) || (p.lookDir.y > 0 && p.camera.rotation_degrees.x > -85):
            p.camera.rotate_x(p.lookDir.y * cameraVelocity)
        p.rotate_y(p.lookDir.x * cameraVelocity)
        if (p.mouseCaptured):
            p.lookDir = Vector2.ZERO
