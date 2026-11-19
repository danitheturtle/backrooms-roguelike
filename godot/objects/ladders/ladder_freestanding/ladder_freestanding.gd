extends Holdable
class_name LadderFreestanding
# implements Targetable
# implements Climbable

@export var isClosed = false

@export var hinge: HingeJoint3D
@export var support: LadderFreestandingSupport
@export var supportCenterOfMass: Marker3D
@onready var initialMotorVelocity = hinge.get_param(HingeJoint3D.PARAM_MOTOR_TARGET_VELOCITY)

# World collides with ladder rigidbody, player does not.
# Instead, player gets their own "static" platforms that move every frame to where the rigidbody is.
# Using collision masking this means the player cannot apply ANY buggy shove force to a ladder, they
# are only able to move it directly. To everything else in the world the ladder behaves normally, and 
# can even be knocked over by other objects
@export var stairsPlatform: AnimatableBody3D
@export var supportPlatform: AnimatableBody3D

func _physics_process(_delta: float) -> void:
    stairsPlatform.transform = transform
    supportPlatform.transform = support.transform

func activate():
    super.activate()
    var currentMotorVelocity: float = hinge.get_param(HingeJoint3D.PARAM_MOTOR_TARGET_VELOCITY)
    hinge.set_param(HingeJoint3D.PARAM_MOTOR_TARGET_VELOCITY, -currentMotorVelocity)
    isClosed = currentMotorVelocity > 0.0

func deactivate(actionTimerFinished: bool) -> bool:
    super.deactivate(actionTimerFinished)
    return true

func interact_start(_player: Player) -> PhysicsBody3D:
    super.interact_start(_player)
    hinge.set_flag(HingeJoint3D.FLAG_ENABLE_MOTOR, true)
    collision_layer = 0b00000000000000100000
    support.center_of_mass = Vector3.ZERO
    support.collision_layer = 0b00000000000000100000
    stairsPlatform.collision_layer = 0b00000000000000000000
    supportPlatform.collision_layer = 0b00000000000000000000
    return self

func interact_stop() -> void:
    super.interact_stop()
    hinge.set_flag(HingeJoint3D.FLAG_ENABLE_MOTOR, false)
    collision_layer = 0b00000000000010000000
    support.collision_layer = 0b00000000000010000000
    support.center_of_mass = supportCenterOfMass.transform.origin
    stairsPlatform.collision_layer = 0b00000000000001000000
    supportPlatform.collision_layer = 0b00000000000001000000

func can_player_climb(_player: Player) -> bool:
    return global_basis.y.dot(_player.global_basis.y) > 0.9

func add_collision_exception(_body: Node3D) -> void:
    super.add_collision_exception(_body)
    var existingSupportExceptions := support.get_collision_exceptions()
    if !existingSupportExceptions.has(_body):
        support.add_collision_exception_with(_body)

func del_collision_exception(_body: Node3D) -> void:
    super.del_collision_exception(_body)
    var existingSupportExceptions := support.get_collision_exceptions()
    if existingSupportExceptions.has(_body):
        support.remove_collision_exception_with(_body)

func apply_hover_self_only():
    super.apply_hover_material()

func apply_hover_material():
    apply_hover_self_only()
    support.apply_hover_self_only()

func clear_hover_self_only():
    super.clear_hover_material()

func clear_hover_material():
    clear_hover_self_only()
    support.clear_hover_self_only()
