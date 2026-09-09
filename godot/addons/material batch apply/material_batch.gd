@tool
extends EditorPlugin

var dock = Control
var button = Button

func _enter_tree() -> void:
	dock = preload("res://addons/material batch apply/dock.gd").new()
	dock.undo_redo = get_undo_redo()
	button = add_control_to_bottom_panel(dock, "Material Batch")
	scene_changed.connect(_on_scene_changed)

func _on_scene_changed(scene_root: Node) -> void:
	dock._refresh_checklist()

func _exit_tree() -> void:
	remove_control_from_bottom_panel(dock)
	dock.queue_free()
