extends Node

const popupTemplates: Dictionary[String,Resource] = {
    "INFO": preload("res://ui/popups/info_template.tscn")
}

@export_multiline var popupText: String
@export_enum("INFO") var popupType: String = "INFO"

var popup = null

func _ready() -> void:
    var parent = get_parent()
    # this doesn't work if parent isn't Area3D
    if parent is not Area3D:
        return
    if parent is Area3D:
        parent.body_entered.connect(on_body_entered)
        parent.body_exited.connect(on_body_exited)

func on_body_entered(node: Node) -> void:
    if node is Player:
        show_popup()

func on_body_exited(node: Node) -> void:
    if node is Player:
        hide_popup()

func show_popup() -> void:
    if popup == null:
        popup = popupTemplates[popupType].instantiate()
        var popupRichText = Utils.get_child_of_type(popup, RichTextLabel, true)
        popupRichText.text = popupText
    SignalBus.popup_displayed.emit(popup)

func hide_popup() -> void:
    SignalBus.popup_closed.emit(popup)
