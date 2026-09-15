extends RigidBody3D
class_name Holdable

var HOVER_OVER_OBJECT_MATERIAL = preload("res://assets/materials/HoverOverObject/HoverOverObject.tres")

@export var heldDistance = 2.0
@export var heldCollisionRadius = 0.5
@export var throwImpulse = 5.0
@export var throwLobFactor = 1.0
@export var propNonsenseLimit = 3 #count collisions to prevent gmod style prop flying
@export var propNonsenseTimeout = 1.5

@onready var meshInstance = Utils.get_child_of_type(self, MeshInstance3D)

var grabOrigin: Vector3 = Vector3(0.0,0.0,0.0)

var cancelFreezeTimeout: bool = false
var repeatCollider: PhysicsBody3D = null
var repeatCollisions: int = 0
var freezeTimeout: Timer = null

func _ready() -> void:
    var grabOriginNode = get_node_or_null("GrabOrigin")
    if (grabOriginNode != null):
        grabOrigin = grabOriginNode.global_position
    freezeTimeout = Timer.new()
    add_child(freezeTimeout)
    freezeTimeout.one_shot = true
    freezeTimeout.wait_time = propNonsenseTimeout
    freezeTimeout.timeout.connect(on_frozen_timer_timeout)
    body_entered.connect(on_body_entered)

func start_action():
    pass

func finish_action(_actionTimerFinished: bool) -> bool:
    return false

func on_hold():
    # move to held layer to avoid collision with player and wierd skyrim-style bullshit
    collision_layer = 0b00000000000000100000

func on_drop():
    collision_layer = 0b00000000000000000001

func on_throw():
    pass

func on_rotate_start(): pass

func on_rotate_stop(): pass

func apply_hover_material():
    for nextMaterial in Utils.get_materials_on_mesh(meshInstance):
        HOVER_OVER_OBJECT_MATERIAL.next_pass = nextMaterial
        meshInstance.set_surface_override_material(0, HOVER_OVER_OBJECT_MATERIAL)

func clear_hover_material():
    if meshInstance == null: return
    for surfaceIndex in meshInstance.mesh.get_surface_count():
        var surfaceMaterial = meshInstance.get_surface_override_material(surfaceIndex)
        if surfaceMaterial == HOVER_OVER_OBJECT_MATERIAL:
            meshInstance.set_surface_override_material(surfaceIndex, null)

var colliders: Array[PhysicsBody3D]
func on_body_entered(body: PhysicsBody3D):
    # if held, do nothing
    if get_collision_layer_value(6): return
    # if colliding body is not held, do nothing
    if !body.get_collision_layer_value(6): return
    print("held object entered")
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
    print((global_position - repeatCollider.global_position).length_squared())
    if (global_position - repeatCollider.global_position).length_squared() > heldDistance * heldDistance:
        repeatCollider = null
        freeze = false
    else:
        freezeTimeout.start()
