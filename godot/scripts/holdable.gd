extends RigidBody3D
class_name Holdable

const hoverOverObjectMaterial = preload("res://assets/materials/HoverOverObject/HoverOverObject.tres")
var initialSurfaceMaterials: Array[Material] = [] #store the surface material override in the pre-hover state. usually null
var hoveringMaterials: Array[Material] = []
@export var heldDistance: float = 1.5
@export var heldDistanceStep: float = 0.1
@export var maxHeldDistance: float = 1.8
@export var heldCollisionRadius: float = 0.5
@export var throwImpulse: float = 5.0
@export var throwLobFactor: float = 1.0
#count collisions to prevent gmod style prop flying
@export var propNonsenseLimit: float = 4
@export var propNonsenseTimeout: float = 1.25

@onready var meshInstance = Utils.get_child_of_type(self, MeshInstance3D)

var grabOrigin: Vector3 = Vector3(0.0,0.0,0.0)
var initialCollisionLayer: int = 0b00000000000000000001
var initialFriction: float = 1.0
var cancelFreezeTimeout: bool = false
var repeatCollider: PhysicsBody3D = null
var repeatCollisions: int = 0
var freezeTimeout: Timer = null
var holdingPlayer: Player = null

var grabbed: bool: get = get_grabbed
func get_grabbed() -> bool: return mass <= holdingPlayer.MAX_GRAB_MASS
var dragged: bool: get = get_dragged
func get_dragged() -> bool: return mass > holdingPlayer.MAX_GRAB_MASS

func _ready() -> void:
    for nextMaterial in Utils.get_materials_on_mesh(meshInstance):
        var dupedHoverMaterial = hoverOverObjectMaterial.duplicate()
        dupedHoverMaterial.next_pass = nextMaterial
        hoveringMaterials.append(dupedHoverMaterial)
    # very occasionally props will already be using the surface override, which this script uses for hovering
    # store previous value so it can be reset
    for nextSurfaceIndex in meshInstance.mesh.get_surface_count():
        initialSurfaceMaterials.append(meshInstance.get_surface_override_material(nextSurfaceIndex))
    var grabOriginNode = get_node_or_null("GrabOrigin")
    if (grabOriginNode != null):
        grabOrigin = grabOriginNode.global_position
    initialCollisionLayer = collision_layer
    initialFriction = 1.0 if physics_material_override == null else physics_material_override.friction
    freezeTimeout = Timer.new()
    add_child(freezeTimeout)
    freezeTimeout.one_shot = true
    freezeTimeout.wait_time = propNonsenseTimeout
    freezeTimeout.timeout.connect(on_frozen_timer_timeout)
    body_entered.connect(on_body_entered)

func _physics_process(_delta: float) -> void:
    # cap linear velocity for all holdable objects
    if linear_velocity.length_squared() > 1024.0:
        linear_velocity = linear_velocity.normalized() * 32.0
    if angular_velocity.length_squared() > 1024.0:
        angular_velocity = angular_velocity.normalized() * 32.0

func activate(): pass

## return true to prevent throwing behavior
func deactivate(_actionTimerFinished: bool) -> bool:
    return false

# occasionally a holdable is acting as a handle, with the primary holdable being another object.
# return the holdable the interaction is intended for
func on_hold(_player: Player) -> Holdable:
    holdingPlayer = _player
    # if grabbing, move to grabbed layer to avoid collision with player and wierd skyrim-style bullshit
    if grabbed:
        collision_layer = 0b00000000000000100000
    elif dragged:
        if physics_material_override != null:
            physics_material_override.friction = 0.0
    return self

func add_collision_exception(_body: Node3D) -> void:
    var existingExceptions := get_collision_exceptions()
    if !existingExceptions.has(_body):
        add_collision_exception_with(_body)

func del_collision_exception(_body: Node3D) -> void:
    var existingExceptions := get_collision_exceptions()
    if existingExceptions.has(_body):
        remove_collision_exception_with(_body)

func on_drop():
    holdingPlayer = null
    if collision_layer != initialCollisionLayer:
        collision_layer = initialCollisionLayer
    if physics_material_override != null && physics_material_override.friction != initialFriction:
        physics_material_override.friction = initialFriction

func on_throw(): pass

func on_rotate_start(): pass

func on_rotate_stop(): pass

func apply_hover_material():
    for surfaceIndex in meshInstance.mesh.get_surface_count():
        meshInstance.set_surface_override_material(surfaceIndex, hoveringMaterials[surfaceIndex])

func clear_hover_material():
    if meshInstance == null: return
    for surfaceIndex in meshInstance.mesh.get_surface_count():
        var surfaceMaterial = meshInstance.get_surface_override_material(surfaceIndex)
        if surfaceMaterial == hoveringMaterials[surfaceIndex]:
            meshInstance.set_surface_override_material(surfaceIndex, initialSurfaceMaterials[surfaceIndex])

func on_body_entered(body: PhysicsBody3D):
    # if held, do nothing
    if get_collision_layer_value(6): return
    # if colliding body is not held, do nothing
    if !body.get_collision_layer_value(6): return
    if (body == repeatCollider):
        freezeTimeout.start()
        if (repeatCollisions > propNonsenseLimit):
            freeze_mode = RigidBody3D.FREEZE_MODE_STATIC
            freeze = true
        else:
            repeatCollisions += 1
    else:
        repeatCollider = body
        repeatCollisions = 0

func on_frozen_timer_timeout():
    if (global_position - repeatCollider.global_position).length_squared() > heldDistance * heldDistance:
        repeatCollider = null
        freeze = false
    else:
        freezeTimeout.start()
