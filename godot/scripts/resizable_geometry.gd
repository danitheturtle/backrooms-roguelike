@abstract
@tool
class_name ResizableGeometry
extends StaticBody3D

@export_range(0.5,24.0,0.5, "prefer_slider", "or_greater") var voxelWidth: float = 2.0: set = set_voxel_width
@export_range(0.5,24.0,0.5, "prefer_slider", "or_greater") var voxelHeight: float = 2.0: set = set_voxel_height
@export_range(0.5,24.0,0.5, "prefer_slider", "or_greater") var voxelDepth: float = 2.0: set = set_voxel_depth
@export var defaultMaterial: BaseMaterial3D = null: set = set_default_material
@export var selectableChildren: bool = false
@export_group("Extend Collision", "extendCollision")
@export var extendCollisionLength: float = 0.5: set = set_extend_collision_length
@export var extendCollisionX: bool = false: set = set_extend_collision_x
@export var extendCollisionY: bool = false: set = set_extend_collision_y
@export var extendCollisionZ: bool = false: set = set_extend_collision_z

var width: float = 1.0: set = set_width
var height: float = 1.0: set = set_height
var depth: float = 1.0: set = set_depth
@abstract func set_width(val: float) -> void
@abstract func set_height(val: float) -> void
@abstract func set_depth(val: float) -> void
@abstract func set_default_material(val: BaseMaterial3D) -> void
func set_voxel_width(val: float):
    voxelWidth = val
    set_width(val * Const.VOXEL)
func set_voxel_height(val: float):
    voxelHeight = val
    set_height(val * Const.VOXEL)
func set_voxel_depth(val: float):
    voxelDepth = val
    set_depth(val * Const.VOXEL)
func set_extend_collision_length(val: float):
    extendCollisionLength = val
    set_extend_collision_x(extendCollisionX)
    set_extend_collision_y(extendCollisionY)
    set_extend_collision_z(extendCollisionZ)
func set_extend_collision_x(val: bool):
    extendCollisionX = val
    set_width(width)
func set_extend_collision_y(val: bool):
    extendCollisionY = val
    set_height(height)
func set_extend_collision_z(val: bool):
    extendCollisionZ = val
    set_depth(depth)

var collider: CollisionShape3D

# refs to resize before node enters tree
func _notification(what: int):
    if what == Node.NOTIFICATION_SCENE_INSTANTIATED: grab_refs()

func grab_refs() -> void:
    collider = get_node("CollisionShape3D")

func _ready() -> void:
    if Engine.is_editor_hint():
        on_editor_ready()
    else:
        cleanup_unused()

func on_editor_ready() -> void:
    # must always be editable relative to parent for sizing props to work. enforce here
    var container: Node = get_parent()
    if is_instance_valid(container):
        if !container.is_editable_instance(self):
            container.set_editable_instance(self, true)
            set_display_folded(true)
            emit_signal("script_changed")
    # wire up selection to always select parent
    EditorInterface.get_selection().connect('selection_changed', on_selection_changed)
    set_extend_collision_length(extendCollisionLength)
    set_width(width)
    set_height(height)
    set_depth(depth)

@abstract func cleanup_unused() -> void

func on_selection_changed():
    if selectableChildren: return
    var editorSelection = EditorInterface.get_selection()
    var selected = editorSelection.get_selected_nodes()
    if selected.size() == 1 && is_ancestor_of(selected[0]):
        var selectedChild = selected[0]
        editorSelection.add_node(self)
        editorSelection.remove_node(selectedChild)
        set_display_folded(true)
        emit_signal("script_changed")

func show_hide_child(child: Node, shouldShow: bool = false):
    if !is_instance_valid(child): return
    if !shouldShow:
        child.hide()
        child.process_mode = Node.PROCESS_MODE_DISABLED
    else:
        child.show()
        child.process_mode = Node.PROCESS_MODE_INHERIT
