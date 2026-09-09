@tool
extends Control

var status_dialog: AcceptDialog
var checklist_container: VBoxContainer
var apply_button: Button
var clear_button: Button
var material_picker: EditorResourcePicker
var mesh_checklistbox: Array = []
var undo_redo: EditorUndoRedoManager
var _poll_timer: Timer

func _ready() -> void:
	name = "Material Batch"
	auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	set_anchors_preset(Control.PRESET_FULL_RECT)
	custom_minimum_size = Vector2(0, 400)

	var margin = MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_bottom", 6)
	add_child(margin)

	var main_vbox = VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 4)
	margin.add_child(main_vbox)
	
	status_dialog = AcceptDialog.new()
	add_child(status_dialog)
	
	var material_label = Label.new()
	material_label.text = "Material:"
	main_vbox.add_child(material_label)
	
	material_picker = EditorResourcePicker.new()
	material_picker.base_type = "Material"
	material_picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_vbox.add_child(material_picker)
	
	var search_box = LineEdit.new()
	search_box.placeholder_text = "Search node..."
	search_box.clear_button_enabled = true
	search_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	search_box.text_changed.connect(_on_search_text_changed)
	main_vbox.add_child(search_box)
	
	var scroll = ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_vbox.add_child(scroll)
	
	checklist_container = VBoxContainer.new()
	checklist_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	checklist_container.add_theme_constant_override("separation", 4)
	scroll.add_child(checklist_container)
	
	var button_row = HBoxContainer.new()
	button_row.add_theme_constant_override("separation", 4)
	main_vbox.add_child(button_row)
	
	clear_button = Button.new()
	clear_button.text = "Clear"
	clear_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	clear_button.custom_minimum_size = Vector2(0, 28)
	clear_button.pressed.connect(_on_clear_pressed)
	button_row.add_child(clear_button)
	
	apply_button = Button.new()
	apply_button.text = "Apply"
	apply_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	apply_button.custom_minimum_size = Vector2(0, 28)
	apply_button.pressed.connect(_on_apply_pressed)
	button_row.add_child(apply_button)
	
	_refresh_checklist()
	_poll_timer = Timer.new()
	_poll_timer.wait_time = 1.0
	_poll_timer.autostart = true
	_poll_timer.timeout.connect(_on_poll_timeout)
	add_child(_poll_timer)

func _on_poll_timeout() -> void:
	var scene_root = EditorInterface.get_edited_scene_root()
	if scene_root == null:
		return
	var found: Array = []
	_collect_mesh_instantes(scene_root, found)
	if found.size() != mesh_checklistbox.size():
		_refresh_checklist()
		return
	for i in found.size():
		if found[i] != mesh_checklistbox[i]["node"]:
			_refresh_checklist()
			return

func _show_message(text: String) -> void:
	status_dialog.dialog_text = text
	status_dialog.popup_centered()

func _on_search_text_changed(new_text: String) -> void:
	var search_lower = new_text.to_lower()
	for entry in mesh_checklistbox:
		var node_name = entry["node"].name.to_lower()
		entry["checkbox"].visible = search_lower.is_empty() or node_name.contains(search_lower)

func _refresh_checklist() -> void:
	for child in checklist_container.get_children():
		child.queue_free()
	mesh_checklistbox.clear()
	
	var scene_root = EditorInterface.get_edited_scene_root()
	if scene_root == null:
		return
	
	var found: Array = []
	_collect_mesh_instantes(scene_root, found)
	
	for mesh_node in found:
		var checkbox = CheckBox.new()
		checkbox.text = mesh_node.name
		checklist_container.add_child(checkbox)
		mesh_checklistbox.append({"checkbox": checkbox, "node": mesh_node})

func _collect_mesh_instantes(node: Node, found: Array):
	if node is MeshInstance3D:
		found.append(node)
	for child in node.get_children():
		_collect_mesh_instantes(child, found)

func _on_apply_pressed() -> void:
	var material = material_picker.edited_resource
	if material == null:
		_show_message("Material Batch Apply: no material selected.")
		return
	
	if mesh_checklistbox.is_empty():
		_show_message("Material Batch Apply: no MeshInstance3D in this scene.")
		return
	
	var checked_entries: Array = []
	for entry in mesh_checklistbox:
		if entry["checkbox"].button_pressed:
			checked_entries.append(entry)
		
	if checked_entries.is_empty():
		_show_message("Material Batch Apply: no node checked.")
		return
	
	undo_redo.create_action("Material Batch Apply: Apply Material")
	for entry in checked_entries:
		var node = entry["node"]
		undo_redo.add_do_property(node, "material_override", material)
		undo_redo.add_undo_property(node, "material_override", node.material_override)
	undo_redo.commit_action()
	
	_show_message("Material Batch Apply: applied to %d node(s)." % checked_entries.size())

func _on_clear_pressed() -> void:
	if mesh_checklistbox.is_empty():
		_show_message("Material Batch Apply: no MeshInstance3D in this scene.")
		return
	
	var checked_entries: Array = []
	for entry in mesh_checklistbox:
		if entry["checkbox"].button_pressed:
			checked_entries.append(entry)
	
	if checked_entries.is_empty():
		_show_message("Material Batch Apply: no node checked.")
		return
	
	var cleared_count = 0
	var skipped_count = 0
	undo_redo.create_action("Material Batch Apply: Clear Override")
	for entry in checked_entries:
		var node = entry["node"]
		if node.material_override == null:
			skipped_count += 1
			continue
		undo_redo.add_do_property(node, "material_override", null)
		undo_redo.add_undo_property(node, "material_override", node.material_override)
		cleared_count += 1
	undo_redo.commit_action()
	
	if cleared_count == 0:
		_show_message("Material Batch Apply: no override found on checked node(s).")
	else:
		_show_message("Material Batch Apply: cleared %d node(s), %d already had no override." % [cleared_count, skipped_count])
