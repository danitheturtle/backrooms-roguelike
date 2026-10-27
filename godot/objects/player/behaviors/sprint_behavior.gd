class_name SprintBehavior
extends PlayerBehavior

func can_act() -> bool:
    if (p.b.squeeze.active || p.b.crawl.active || p.climbing):
        return false
    elif (p.b.crouch.active):
        return p.can_stand()
    elif (!p.b.vault.active):
        return p.onFloorLastFrame
    return false
func start_action() -> void:
    active = true
    p.try_clear_hover_state()
    if (p.grabbing || p.dragging || p.photographing):
        # stop photographing
        p.handle_drop()
func process_action(_delta: float) -> void: pass
func end_action() -> void: pass
