@tool
extends Node3D

@onready var ladder: WoodenLadder = $WoodenLadder
@onready var support: RigidBody3D = $SupportRigidBody
@onready var hinge: HingeJoint3D = $LadderHinge

@export var isClosed = false:
    set(_val):
        if _val:
            ladder.rotation_degrees.z = 20.0
            support.rotation_degrees.z = -20.0
            ladder.position.y = 2.125
            support.position.y = 2.125
            hinge.position.y = 2.125
            isClosed = true
        else:
            ladder.rotation_degrees.z = 0.0
            support.rotation_degrees.z = 0.0
            ladder.position.y = 2.0
            support.position.y = 2.0
            hinge.position.y = 2.0
            isClosed = false
    get:
        return isClosed
