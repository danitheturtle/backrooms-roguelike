class_name RopeAnchor
extends Targetable

@onready var rope: Rope = get_parent()

func interact_stop() -> void:
    # return ammo stored in rope
    player.behaviors.rope.ammo += rope.length
    rope.queue_free()
    super.interact_stop()
