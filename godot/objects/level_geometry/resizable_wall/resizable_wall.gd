@tool
class_name ResizableWall
extends StaticBody3D

@export_range(0.25,16.0,0.25, "prefer_slider", "or_greater") var width: float = 1.0: set = set_width
@export_range(0.25,16.0,0.25, "prefer_slider", "or_greater") var height: float = 1.0: set = set_height
@export_range(0.25,16.0,0.25, "prefer_slider", "or_greater") var depth: float = 1.0: set = set_depth
@export var defaultMaterial: BaseMaterial3D = null: set = set_default_material
@export var selectableChildren: bool = false
@export_group("Visible Sides", "show")
@export var showXNeg: bool = true: set = set_show_x_neg
@export var showXPos: bool = true: set = set_show_x_pos
@export var showYNeg: bool = true: set = set_show_y_neg
@export var showYPos: bool = true: set = set_show_y_pos
@export var showZNeg: bool = true: set = set_show_z_neg
@export var showZPos: bool = true: set = set_show_z_pos
@export_group("Material Override", "material")
@export var materialXNeg: BaseMaterial3D = null: set = set_material_x_neg
@export var materialXPos: BaseMaterial3D = null: set = set_material_x_pos
@export var materialYNeg: BaseMaterial3D = null: set = set_material_y_neg
@export var materialYPos: BaseMaterial3D = null: set = set_material_y_pos
@export var materialZNeg: BaseMaterial3D = null: set = set_material_z_neg
@export var materialZPos: BaseMaterial3D = null: set = set_material_z_pos
@export_group("Occlusion Planes", "occlude")
@export var occludeXY: bool = false: set = set_occlude_xy
@export var occludeZY: bool = false: set = set_occlude_zy
@export var occludeXZ: bool = false: set = set_occlude_xz

@onready var collider: CollisionShape3D = $Collider
# each axis shares a surface mesh, only need to change one to change size
@onready var meshXNeg: MeshInstance3D = $MeshXNeg
@onready var meshXPos: MeshInstance3D = $MeshXPos
@onready var meshYNeg: MeshInstance3D = $MeshYNeg
@onready var meshYPos: MeshInstance3D = $MeshYPos
@onready var meshZNeg: MeshInstance3D = $MeshZNeg
@onready var meshZPos: MeshInstance3D = $MeshZPos
@onready var occluderXY: OccluderInstance3D = $OccluderXY
@onready var occluderZY: OccluderInstance3D = $OccluderZY
@onready var occluderXZ: OccluderInstance3D = $OccluderXZ

func set_width(val: float):
    width = val
    if !is_instance_valid(collider): return
    collider.shape.size.x = val
    meshZNeg.mesh.size.x = val
    meshYNeg.mesh.size.x = val
    occluderXY.occluder.size.x = val * 0.95
    occluderXZ.occluder.size.x = val * 0.95
    meshXNeg.position.x = -val/2.0
    meshXPos.position.x = val/2.0
func set_height(val: float):
    height = val
    if !is_instance_valid(collider): return
    collider.shape.size.y = val
    meshXNeg.mesh.size.y = val
    meshZNeg.mesh.size.y = val
    occluderXY.occluder.size.y = val * 0.95
    occluderZY.occluder.size.y = val * 0.95
    meshYNeg.position.y = -val/2.0
    meshYPos.position.y = val/2.0
func set_depth(val: float):
    depth = val
    if !is_instance_valid(collider): return
    collider.shape.size.z = val
    meshYNeg.mesh.size.y = val
    meshXNeg.mesh.size.x = val
    occluderZY.occluder.size.x = val * 0.95
    occluderXZ.occluder.size.y = val * 0.95
    meshZNeg.position.z = -val/2.0
    meshZPos.position.z = val/2.0
func set_show_x_neg(val: bool):
    showXNeg = val
    show_hide_child(meshXNeg, val)
func set_show_x_pos(val: bool):
    showXPos = val
    show_hide_child(meshXPos, val)
func set_show_y_neg(val: bool):
    showYNeg = val
    show_hide_child(meshYNeg, val)
func set_show_y_pos(val: bool):
    showYPos = val
    show_hide_child(meshYPos, val)
func set_show_z_neg(val: bool):
    showZNeg = val
    show_hide_child(meshZNeg, val)
func set_show_z_pos(val: bool):
    showZPos = val
    show_hide_child(meshZPos, val)
func set_default_material(val: BaseMaterial3D):
    defaultMaterial = val
    if materialXNeg == null && is_instance_valid(meshXNeg): meshXNeg.material_override = val
    if materialXPos == null && is_instance_valid(meshXPos): meshXPos.material_override = val
    if materialYNeg == null && is_instance_valid(meshYNeg): meshYNeg.material_override = val
    if materialYPos == null && is_instance_valid(meshYPos): meshYPos.material_override = val
    if materialZNeg == null && is_instance_valid(meshZNeg): meshZNeg.material_override = val
    if materialZPos == null && is_instance_valid(meshZPos): meshZPos.material_override = val
func set_material_x_neg(val: BaseMaterial3D):
    materialXNeg = val
    update_material_for_side(meshXNeg, val)
func set_material_x_pos(val: BaseMaterial3D):
    materialXPos = val
    update_material_for_side(meshXPos, val)
func set_material_y_neg(val: BaseMaterial3D):
    materialYNeg = val
    update_material_for_side(meshYNeg, val)
func set_material_y_pos(val: BaseMaterial3D):
    materialYPos = val
    update_material_for_side(meshYPos, val)
func set_material_z_neg(val: BaseMaterial3D):
    materialZNeg = val
    update_material_for_side(meshZNeg, val)
func set_material_z_pos(val: BaseMaterial3D):
    materialZPos = val
    update_material_for_side(meshZPos, val)
func set_occlude_xy(val: bool):
    occludeXY = val
    show_hide_child(occluderXY, val)
func set_occlude_zy(val: bool):
    occludeZY = val
    show_hide_child(occluderZY, val)
func set_occlude_xz(val: bool):
    occludeXZ = val
    show_hide_child(occluderXZ, val)

func _ready() -> void:
    if Engine.is_editor_hint():
        in_editor_ready()
    else:
        if !showXNeg: meshXNeg.queue_free()
        if !showXPos: meshXPos.queue_free()
        if !showYNeg: meshYNeg.queue_free()
        if !showYPos: meshYPos.queue_free()
        if !showZNeg: meshZNeg.queue_free()
        if !showZPos: meshZPos.queue_free()
        if !occludeXY: occluderXY.queue_free()
        if !occludeZY: occluderZY.queue_free()
        if !occludeXZ: occluderXZ.queue_free()

func in_editor_ready():
    # must always be editable relative to parent for sizing props to work. enforce here
    var container: Node = get_parent()
    if is_instance_valid(container):
        if !container.is_editable_instance(self):
            container.set_editable_instance(self, true)
    # wire up selection to always select parent
    EditorInterface.get_selection().connect('selection_changed', on_selection_changed)
    await get_tree().process_frame
    # call setters to prevent node-out-of-date issues
    width = width
    height = height
    depth = depth
    showXNeg = showXNeg
    showXPos = showXPos
    showYNeg = showYNeg
    showYPos = showYPos
    showZNeg = showZNeg
    showZPos = showZPos
    occludeXY = occludeXY
    occludeZY = occludeZY
    occludeXZ = occludeXZ

func on_selection_changed():
    if selectableChildren: return
    var editorSelection = EditorInterface.get_selection()
    var selected = editorSelection.get_selected_nodes()
    if selected.size() == 1 && is_ancestor_of(selected[0]):
        var selectedChild = selected[0]
        editorSelection.add_node(self)
        editorSelection.remove_node(selectedChild)

func show_hide_child(child: Node, shouldShow: bool = false):
    if !is_instance_valid(child): return
    if !shouldShow:
        child.hide()
        child.process_mode = Node.PROCESS_MODE_DISABLED
    else:
        child.show()
        child.process_mode = Node.PROCESS_MODE_INHERIT

func update_material_for_side(updatedMesh: MeshInstance3D, newMaterial: BaseMaterial3D):
    if !is_instance_valid(updatedMesh): return
    if newMaterial == null:
        updatedMesh.material_override = defaultMaterial
    else:
        updatedMesh.material_override = newMaterial
