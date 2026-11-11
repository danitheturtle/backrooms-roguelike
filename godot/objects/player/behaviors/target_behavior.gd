class_name TargetBehavior
extends PlayerBehavior

const HoverMaterialRef = preload("res://assets/materials/HoverOverObject/HoverOverObject.tres")
const cannotTransitionFrom: Array[StringName] = [&"drag", &"grab", &"film_camera"]

static func get_hover_materials(mesh: MeshInstance3D) -> Array[Material]:
    var hoverMaterials: Array[Material] = []
    for nextMaterial in Utils.get_materials_on_mesh(mesh):
        var dupedHoverMaterial = HoverMaterialRef.duplicate()
        dupedHoverMaterial.next_pass = nextMaterial
        hoverMaterials.append(dupedHoverMaterial)
    return hoverMaterials

# garunteed to be in targetable group, a pseudo-interface with shared methods. see obsidian docs
var ref: CollisionObject3D
var justInteracted: bool
var targetRayCast: RayCast3D
var targetedPoint: Vector3

## target behavior uses ref to determine whether its active
func get_active() -> bool: return ref != null

func set_active(_nextVal: bool) -> void: pass

func player_ready() -> void:
    targetRayCast = p.get_node("Camera/TargetRayCast")
    targetRayCast.target_position.z = -p.TARGETING_DISTANCE
    targetedPoint = Vector3.ZERO

func reinit() -> void:
    justInteracted = false
    if ref != null:
        ref.clear_hover_material()
    ref = null

func can_act() -> bool:
    return pb.none(cannotTransitionFrom)

func start_action() -> void: pass

func process_action(_delta: float) -> void:
    if can_act():
        var nextTargetRef = targetRayCast.get_collider()
        if ref != nextTargetRef:
            stop_action()
            if (nextTargetRef != null && nextTargetRef.is_in_group("targetable")):
                ref = nextTargetRef
                targetedPoint = targetRayCast.get_collision_point()
                ref.apply_hover_material()

func stop_action() -> void:
    reinit()

# some targetable things like buttons might be actavatable in states where holding isn't possible
func stop_if_target_is_holdable():
    if ref is Holdable: stop_action()
