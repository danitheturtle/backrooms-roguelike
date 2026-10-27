class_name JumpBehavior
extends PlayerBehavior

var justJumped: bool = false

func reinit() -> void:
    super.reinit()
    justJumped = false

func can_act() -> bool:
    return !active && !p.b.vault.active && !p.b.crouch.active && !p.b.crawl.active && !p.squeezing && !p.photographing && (p.onFloorLastFrame || p.climbing)
func start_action() -> void:
    p.try_clear_hover_state()
    p.velocity += Vector3(0,p.JUMP_IMPULSE,0)
    active = true
    if p.dragging: p.handle_drop()
    if p.climbing: p.stop_climb()
func process_action(_delta: float) -> void: pass
func end_action() -> void:
    active = false
    p.b.vault.active = false
