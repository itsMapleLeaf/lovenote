@tool
class_name EditorPanelStyleBox
extends StyleBoxFlat

@export_range(0, 6, 1) var shade := 0:
	set(value):
		shade = value
		bg_color = _base_color.darkened(shade * 0.15)

var _base_color: Color:
	get:
		return EditorInterface.get_editor_settings().get_setting("interface/theme/base_color")

func _init() -> void:
	shade = shade
