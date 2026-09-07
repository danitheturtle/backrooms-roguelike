extends CanvasLayer
class_name HUDMenu

@onready var crosshair = $MarginContainer/GridContainer/CenterContainer/Crosshair
@onready var popup = $MarginContainer/GridContainer/BottomContainer/PopupPanel

func _ready() -> void:
    SignalBus.popup_displayed.connect(on_popup_displayed)
    SignalBus.popup_closed.connect(on_popup_closed)

func on_popup_displayed(innerPopup: Control) -> void:
    if innerPopup.get_parent() != popup:
        popup.add_child(innerPopup)
        innerPopup.owner = get_tree().root
    if popup.get_child_count() > 0:
        popup.show()

func on_popup_closed(innerPopup: Control) -> void:
    if innerPopup.get_parent() == popup:
        popup.remove_child(innerPopup)
    if popup.get_child_count() == 0:
        popup.hide()
