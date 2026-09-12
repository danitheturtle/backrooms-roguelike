extends Holdable
class_name WoodenLadder

@export var isClosed = false

@onready var hinge: HingeJoint3D = $"../LadderHinge"
@onready var support: RigidBody3D = $"../SupportRigidBody"
@onready var initialMotorVelocity = hinge.get_param(HingeJoint3D.PARAM_MOTOR_TARGET_VELOCITY)
@onready var stairsPlatform: AnimatableBody3D = $"../StairsPlatform"
@onready var supportPlatform: AnimatableBody3D = $"../SupportPlatform"

func _physics_process(_delta: float) -> void:
    stairsPlatform.transform = transform
    supportPlatform.transform = support.transform

func on_hold():
    super.on_hold()
    hinge.set_flag(HingeJoint3D.FLAG_ENABLE_MOTOR, true)
    collision_layer = 0b00000000000000100000
    support.collision_layer = 0b00000000000000100000
    stairsPlatform.collision_layer = 0b00000000000000000000
    supportPlatform.collision_layer = 0b00000000000000000000

func on_drop():
    super.on_drop()
    hinge.set_flag(HingeJoint3D.FLAG_ENABLE_MOTOR, false)
    collision_layer = 0b00000000000010000000
    support.collision_layer = 0b00000000000010000000
    stairsPlatform.collision_layer = 0b00000000000001000000
    supportPlatform.collision_layer = 0b00000000000001000000

func on_rotate_start():
    super.on_rotate_start()
    hinge.set_param(HingeJoint3D.PARAM_MOTOR_TARGET_VELOCITY, -initialMotorVelocity)

func on_rotate_stop():
    super.on_rotate_stop()
    hinge.set_param(HingeJoint3D.PARAM_MOTOR_TARGET_VELOCITY, initialMotorVelocity)
