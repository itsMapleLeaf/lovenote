@tool
extends PanelContainer

const NodeHelpers = preload("res://addons/stageplay/node_helpers.gd")

var shade := 0
var margin := 0

func _ready() -> void:
	_update_theme()

func _on_theme_changed() -> void:
	var theme_shade := get_theme_constant("shade", "EditorPanel") if has_theme_constant("shade", "EditorPanel") else 0
	var theme_margin := get_theme_constant("margin", "EditorPanel") if has_theme_constant("margin", "EditorPanel") else 0

	if theme_shade == shade and theme_margin == margin:
		return

	shade = theme_shade
	margin = theme_margin
	_update_theme()


func _update_theme() -> void:
	var editor_settings := EditorInterface.get_editor_settings()
	var base_color: Color = editor_settings.get_setting('interface/theme/base_color')

	var style := StyleBoxFlat.new()
	style.bg_color = base_color.darkened(shade * 0.15)
	style.set_content_margin_all(margin)
	style.set_corner_radius_all(4)
	add_theme_stylebox_override("panel", style)
