class_name JumpBehavior
extends PlayerBehavior

var justJumped: bool = false

func reinit() -> void:
    super.reinit()
    justJumped = false

func can_act() -> bool:
    return !active && !p.b.vault.active && !p.b.crouch.active && !p.b.crawl.active && !p.b.squeeze.active && !p.photographing && (p.onFloorLastFrame || p.b.climb.active)
func start_action() -> void:
    p.try_clear_hover_state()
    p.velocity += Vector3(0,p.JUMP_IMPULSE,0)
    active = true
    if p.b.drag.active: p.b.drag.stop_action()
    if p.b.climb.active: p.b.climb.stop_action()
func process_action(_delta: float) -> void: pass
func stop_action() -> void:
    active = false
    p.b.vault.active = false
