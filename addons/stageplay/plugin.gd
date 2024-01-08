@tool
extends EditorPlugin

var main_panel_node: StagePlayEditor

func _get_plugin_name() -> String:
	return "StagePlay"

func _get_plugin_icon() -> Texture2D:
	return EditorInterface.get_editor_theme().get_icon("AnimationMixer", "EditorIcons")

func _has_main_screen() -> bool:
	return true

func _enter_tree() -> void:
	main_panel_node = StagePlayEditor.create()
	EditorInterface.get_editor_main_screen().add_child(main_panel_node)
	_make_visible(false)
	main_panel_node.unpack(Unpacker.from(
		load("res://addons/stageplay/template.gd").get_template_data()
	))

func _exit_tree() -> void:
	if main_panel_node: main_panel_node.queue_free()

func _make_visible(visible: bool) -> void:
	if main_panel_node: main_panel_node.visible = visible
