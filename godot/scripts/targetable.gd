class_name Targetable
extends CollisionObject3D

## targetable always has visible mesh
@onready var meshInstance = Utils.get_child_of_type(self, MeshInstance3D)
## store the surface material override in the pre-hover state. usually null
@onready var hoverMaterials: Array[Material] = TargetBehavior.get_hover_materials(meshInstance)
## very occasionally props will already be using the surface override, which this script uses for hovering store initial value so it can be reset
@onready var initialSurfaceMaterials: Array[Material] = Utils.get_surface_overrides_on_mesh(meshInstance)

var player: Player = null

func apply_hover_material() -> void:
    Utils.apply_surface_overrides(meshInstance, hoverMaterials)

func clear_hover_material() -> void:
    Utils.apply_surface_overrides(meshInstance, initialSurfaceMaterials)

# target might be a handle, return object player is interacting with
func interact_start(_player: Player) -> CollisionObject3D:
    print(_player)
    player = _player
    return self

func interact_stop() -> void:
    player = null
