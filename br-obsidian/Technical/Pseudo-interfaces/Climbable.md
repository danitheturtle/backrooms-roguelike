global group: "Climbable"

```gdscript
@onready var climbPath: Path3D = $ClimbPath
@abstract func can_player_climb(_player: Player) -> bool
```