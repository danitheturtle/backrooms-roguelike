@abstract
class_name PlayerBehavior

var player: Player

var active: bool: get = get_active, set = set_active
func get_active() -> bool: return active
func set_active(nextVal: bool) -> void: active = nextVal

var p: Player: get = get_player
func get_player() -> Player: return player

var pb: BehaviorState: get = get_player_behaviors
func get_player_behaviors() -> BehaviorState: return player.behaviors

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
