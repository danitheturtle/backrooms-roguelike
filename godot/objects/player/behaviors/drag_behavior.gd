class_name DragBehavior
extends PlayerBehavior

const MAX_DRAG_MASS: float = 150.0

func can_act() -> bool:
    if (!active && !p.b.grab.active && !p.b.jump.active && !p.b.vault.active && !p.b.crouch.active && !p.b.crawl.active && !p.b.squeeze.active && !p.b.sprint.active && !p.b.climb.active && !p.photographing && p.onFloorLastFrame):
        if (p.objectInReachRef != null && p.objectInReachRef.mass > MAX_DRAG_MASS):
            return false
        else:
            return true
    else:
        return false
func start_action() -> void:
    p.objectInReachRef.on_hold()
    p.draggedPoint = p.objectInReachRef.to_local(p.grabAnchor.global_position)
    p.heldObjectRef = p.objectInReachRef
    p.heldObjectRef.clear_hover_material()
    active = true
func process_action(_delta: float) -> void: pass
func stop_action() -> void:
    if !active: return
    p.heldObjectRef.on_drop()
    p.heldObjectRef = null
    active = false
    p.grabArm.spring_length = p.grabArmLength
    p.grabArm.shape.radius = p.grabArmShapeRadius
    p.b.stand.start_action()
