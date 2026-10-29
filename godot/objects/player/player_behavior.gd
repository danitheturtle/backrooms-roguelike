@abstract
class_name PlayerBehavior

var player: Player
var active: bool
# shorthand props because the state gets checked a lot and is annoying to type
var p: Player:
    get: return player
var pb: Player.BehaviorState:
    get: return player.behaviors

func _init(_player: Player) -> void:
    player = _player
    active = false
func reinit() -> void: active = false
func player_ready() -> void: pass
func can_act() -> bool: return true
func start_action() -> void:
    if active: return
    active = true
func process_action(_delta: float) -> void: pass
func stop_action() -> void:
    if !active: return
    active = false
