class_name JumpBehavior
extends PlayerBehavior

var justJumped: bool = false

func reinit() -> void:
    super.reinit()
    justJumped = false

func can_act() -> bool:
    return !active && !player.b.vault.active && !player.b.crouch.active && !player.crawling && !player.squeezing && !player.photographing && (player.onFloorLastFrame || player.climbing)
func start_action() -> void:
    player.try_clear_hover_state()
    player.velocity += Vector3(0,player.JUMP_IMPULSE,0)
    active = true
    if player.dragging: player.handle_drop()
    if player.climbing: player.stop_climb()
func process_action(_delta: float) -> void: pass
func end_action() -> void:
    active = false
    player.b.vault.active = false
