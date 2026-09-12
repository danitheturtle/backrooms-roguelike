extends Holdable
class_name WoodenLadder

@export var isClosed = false

@onready var hinge: HingeJoint3D = $"../LadderHinge"
@onready var support: RigidBody3D = $"../SupportRigidBody"
@onready var initialMotorVelocity = hinge.get_param(HingeJoint3D.PARAM_MOTOR_TARGET_VELOCITY)

func on_hold():
    super.on_hold()
    hinge.set_flag(HingeJoint3D.FLAG_ENABLE_MOTOR, true)
    support.collision_layer = 0b00000000000000100000

func on_drop():
    super.on_drop()
    hinge.set_flag(HingeJoint3D.FLAG_ENABLE_MOTOR, false)
    support.collision_layer = 0b00000000000000000001

func on_rotate_start():
    super.on_rotate_start()
    hinge.set_param(HingeJoint3D.PARAM_MOTOR_TARGET_VELOCITY, -initialMotorVelocity)

func on_rotate_stop():
    super.on_rotate_stop()
    hinge.set_param(HingeJoint3D.PARAM_MOTOR_TARGET_VELOCITY, initialMotorVelocity)
