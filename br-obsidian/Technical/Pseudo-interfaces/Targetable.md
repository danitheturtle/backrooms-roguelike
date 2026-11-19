global group: "Targetable"

```gdscript
@onready var meshInstance = Utils.get_child_of_type(self, MeshInstance3D)

@onready var hoverMaterials: Array[Material] = TargetBehavior.get_hover_materials(meshInstance)

@onready var initialSurfaceMaterials: Array[Material] = Utils.get_surface_overrides_on_mesh(meshInstance)

@abstract func apply_hover_material() -> void
@abstract func clear_hover_material() -> void
@abstract func interact_start(_player: Player) -> CollisionObject3D
@abstract func interact_stop() -> void
```