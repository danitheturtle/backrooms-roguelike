class_name LadderFreestandingSupport
extends Holdable

## Override all holdable functions to make this object defer to the parent ladder

@export var ladder: LadderFreestanding

func get_grabbed() -> bool: return ladder.mass <= holdingPlayer.MAX_GRAB_MASS
func get_dragged() -> bool: return ladder.mass > holdingPlayer.MAX_GRAB_MASS

func _ready() -> void:
    for nextMaterial in Utils.get_materials_on_mesh(meshInstance):
        var dupedHoverMaterial = hoverOverObjectMaterial.duplicate()
        dupedHoverMaterial.next_pass = nextMaterial
        hoveringMaterials.append(dupedHoverMaterial)
    for nextSurfaceIndex in meshInstance.mesh.get_surface_count():
        initialSurfaceMaterials.append(meshInstance.get_surface_override_material(nextSurfaceIndex))
    body_entered.connect(on_body_entered)

func _physics_process(_delta: float) -> void:
    # cap linear velocity for all holdable objects
    if linear_velocity.length_squared() > 1024.0:
        linear_velocity = linear_velocity.normalized() * 32.0
    if angular_velocity.length_squared() > 1024.0:
        angular_velocity = angular_velocity.normalized() * 32.0

func activate():
    ladder.activate()

func deactivate(_actionTimerFinished: bool) -> bool:
    return ladder.deactivate(_actionTimerFinished)

func on_hold(_player: Player):
    holdingPlayer = _player
    ladder.on_hold(_player)
    return ladder

func add_collision_exception(_body: Node3D) -> void:
    ladder.add_collision_exception(_body)

func del_collision_exception(_body: Node3D) -> void:
    ladder.del_collision_exception(_body)

func on_drop():
    holdingPlayer = null
    ladder.on_drop()

func on_throw(): pass

func on_rotate_start(): pass

func on_rotate_stop(): pass

func apply_hover_self_only():
    super.apply_hover_material()

func apply_hover_material():
    apply_hover_self_only()
    ladder.apply_hover_self_only()

func clear_hover_self_only():
    super.clear_hover_material()

func clear_hover_material():
    clear_hover_self_only()
    ladder.clear_hover_self_only()

func on_body_entered(body: PhysicsBody3D):
    ladder.on_body_entered(body)
