extends Area3D

@export var trackingObject: Node3D = null
@export var deleteOnSolved: Node3D = null

@onready var alignment: Marker3D = $Alignment

var solverInside: bool = false

func _ready() -> void:
    solverInside = false
    body_entered.connect(on_body_entered)
    body_exited.connect(on_body_exited)

func _process(_delta: float) -> void:
    if solverInside && !State.player.behaviors.grab.active:
        # ensure solver is facing the right way
        var dotProductDifferenceZ = alignment.global_basis.z.dot(trackingObject.global_basis.z)
        var dotProductDifferenceY = alignment.global_basis.y.dot(trackingObject.global_basis.y)
        if dotProductDifferenceZ > 0.95 && dotProductDifferenceY > 0.95:
            deleteOnSolved.queue_free()
            queue_free()

func on_body_entered(_other: Node3D) -> void:
    if _other == trackingObject:
        solverInside = true

func on_body_exited(_other: Node3D) -> void:
    if _other == trackingObject:
        solverInside = false
