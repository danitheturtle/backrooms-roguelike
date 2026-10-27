@abstract
class_name PlayerBehavior

var player: Player
var active: bool

func _init(_player: Player) -> void:
    player = _player
    active = false

func reinit() -> void:
    active = false
@abstract func can_act() -> bool
@abstract func start_action() -> void
@abstract func process_action(_delta: float) -> void
@abstract func end_action() -> void
