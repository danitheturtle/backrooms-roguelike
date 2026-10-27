class_name SqueezeBehavior
extends PlayerBehavior

func can_act() -> bool:
    if (!p.b.crawl.active && !p.b.vault.active && !p.b.crouch.active && !p.climbing && !p.dragging && !p.grabbing):
        return p.onFloorLastFrame
    elif (p.b.crouch.active):
        return p.can_stand()
    else:
        return false
func start_action() -> void:
    p.handle_stand()
    p.try_clear_hover_state()
    p.playerShape.radius = p.SQUEEZE_RADIUS
    p.flashlight.position.x = 0
    p.b.sprint.active = false
    active = true
func process_action(_delta: float) -> void: pass
func end_action() -> void: pass
