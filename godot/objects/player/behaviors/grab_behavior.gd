class_name GrabBehavior
extends PlayerBehavior

const MAX_GRAB_MASS: float = 15.0

func can_act() -> bool:
    if (!p.b.drag.active && !active && !p.b.jump.active && !p.b.vault.active && !p.b.crouch.active && !p.b.crawl.active && !p.b.squeeze.active && !p.b.sprint.active && !p.b.climb.active && !p.photographing && p.onFloorLastFrame):
        if (p.objectInReachRef != null && p.objectInReachRef.mass > MAX_GRAB_MASS):
            return false
        else:
            return true
    else:
        return false
func start_action() -> void:
    p.objectInReachRef.on_hold()
    p.grabArm.spring_length = p.objectInReachRef.heldDistance
    p.grabArm.shape.radius = p.objectInReachRef.heldCollisionRadius
    # causes visual bug as spring arm rapidly shifts if we don't defer
    call_deferred("_handle_start_deferred")
func _handle_start_deferred():
    active = true
    p.heldObjectRef = p.objectInReachRef
    p.heldObjectRef.clear_hover_material()
func process_action(_delta: float) -> void: pass
func stop_action() -> void:
    if !active: return
    p.heldObjectRef.on_drop()
    p.heldObjectRef = null
    active = false
    p.grabArm.spring_length = p.grabArmLength
    p.grabArm.shape.radius = p.grabArmShapeRadius
    p.b.stand.start_action()
