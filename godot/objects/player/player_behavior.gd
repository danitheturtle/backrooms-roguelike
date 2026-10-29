@abstract
class_name PlayerBehavior

var player: Player
var active: bool

var p: Player:
    get: return player
var pb: Player.BehaviorState:
    get: return player.behaviors

func _init(_player: Player) -> void:
    player = _player
    active = false
func player_ready() -> void: pass
func reinit() -> void: active = false
func can_act() -> bool: return true
func start_action() -> void:
    if active: return
    active = true
func process_action(_delta: float) -> void: pass
func stop_action() -> void:
    if !active: return
    active = false
