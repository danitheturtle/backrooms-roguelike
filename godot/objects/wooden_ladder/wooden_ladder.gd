extends Holdable
class_name WoodenLadder

@export var isClosed = false

@onready var hinge: HingeJoint3D = $"../LadderHinge"
@onready var support: RigidBody3D = $"../SupportRigidBody"
@onready var initialMotorVelocity = hinge.get_param(HingeJoint3D.PARAM_MOTOR_TARGET_VELOCITY)

# World collides with ladder rigidbody, player does not.
# Instead, player gets their own "static" platforms that move every frame to where the rigidbody is.
# Using collision masking this means the player cannot apply ANY buggy shove force to a ladder, they
# are only able to move it directly. To everything else in the world the ladder behaves normally, and 
# can even be knocked over by other objects
@onready var stairsPlatform: AnimatableBody3D = $"../StairsPlatform"
@onready var supportPlatform: AnimatableBody3D = $"../SupportPlatform"

func _physics_process(_delta: float) -> void:
    stairsPlatform.transform = transform
    supportPlatform.transform = support.transform

func start_action():
    super.start_action()
    hinge.set_param(HingeJoint3D.PARAM_MOTOR_TARGET_VELOCITY, -initialMotorVelocity)

func finish_action(actionTimerFinished: bool) -> bool:
    super.finish_action(actionTimerFinished)
    hinge.set_param(HingeJoint3D.PARAM_MOTOR_TARGET_VELOCITY, initialMotorVelocity)
    return true

func on_hold():
    super.on_hold()
    hinge.set_flag(HingeJoint3D.FLAG_ENABLE_MOTOR, true)
    collision_layer = 0b00000000000000100000
    support.center_of_mass = Vector3(0.0,0.0,0.0)
    support.collision_layer = 0b00000000000000100000
    stairsPlatform.collision_layer = 0b00000000000000000000
    supportPlatform.collision_layer = 0b00000000000000000000

func on_drop():
    super.on_drop()
    hinge.set_flag(HingeJoint3D.FLAG_ENABLE_MOTOR, false)
    collision_layer = 0b00000000000010000000
    support.collision_layer = 0b00000000000010000000
    support.center_of_mass = Vector3(0.45, -1.05, 0.0)
    stairsPlatform.collision_layer = 0b00000000000001000000
    supportPlatform.collision_layer = 0b00000000000001000000
