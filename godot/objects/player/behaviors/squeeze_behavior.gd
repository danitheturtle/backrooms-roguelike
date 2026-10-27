class_name SqueezeBehavior
extends PlayerBehavior

func can_act() -> bool:
    if (!p.b.crawl.active && !p.b.vault.active && !p.b.crouch.active && !p.b.climb.active && !p.b.drag.active && !p.b.grab.active):
        return p.onFloorLastFrame
    elif (p.b.crouch.active):
        return p.b.stand.can_act()
    else:
        return false
func start_action() -> void:
    p.b.stand.start_action()
    p.try_clear_hover_state()
    p.playerShape.radius = p.SQUEEZE_RADIUS
    p.flashlight.position.x = 0
    p.b.sprint.active = false
    active = true
func process_action(_delta: float) -> void: pass
func stop_action() -> void: pass
