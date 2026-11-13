class_name RopeAnchor
extends Targetable

@onready var controlledRope: Rope = get_parent()

func interact_stop() -> void:
    super.interact_stop()
    # TODO return player rope ammo based on length
    controlledRope.queue_free()
