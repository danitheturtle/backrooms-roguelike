@tool
class_name ResizableFloor
extends ResizableGeometry

@export var shouldOcclude: bool = false: set = set_should_occlude

var expandDir: float = -1.0

var visibleMesh: MeshInstance3D
var occluder: OccluderInstance3D

func grab_refs() -> void:
    super.grab_refs()
    visibleMesh = get_node("MeshInstance3D")
    occluder = get_node("OccluderInstance3D")

func set_width(val: float) -> void:
    width = val
    if !is_instance_valid(collider): return
    collider.shape.size.x = val + (0.0 if !extendCollisionX else 2.0 * extendCollisionLength)
    visibleMesh.mesh.size.x = val
    occluder.occluder.size.x = val * 0.95
func set_height(val: float) -> void:
    height = val
    if !is_instance_valid(collider): return
    collider.shape.size.y = val + (0.0 if !extendCollisionY else extendCollisionLength)
    collider.transform.origin.y = expandDir * collider.shape.size.y / 2.0
func set_depth(val: float) -> void:
    depth = val
    if !is_instance_valid(collider): return
    collider.shape.size.z = val + (0.0 if !extendCollisionZ else 2.0 * extendCollisionLength)
    visibleMesh.mesh.size.y = val
    occluder.occluder.size.y = val * 0.95
func set_default_material(val: BaseMaterial3D) -> void:
    defaultMaterial = val
    if is_instance_valid(visibleMesh):
        visibleMesh.material_override = val
func set_should_occlude(val: bool) -> void:
    shouldOcclude = val
    show_hide_child(occluder, val)

func on_editor_ready():
    super.on_editor_ready()
    set_should_occlude(shouldOcclude)

func cleanup_unused() -> void:
    if !shouldOcclude && is_instance_valid(occluder): occluder.queue_free()
