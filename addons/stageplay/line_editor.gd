@tool
class_name LineEditor
extends Node

const NodeHelpers = preload("res://addons/stageplay/node_helpers.gd")

@onready var speaker_field: TextField = %SpeakerField
@onready var directives: Control = %Directives
@onready var add_directive_button: Button = %AddDirectiveButton

@export var speaker: String:
	set(value):
		speaker = value
		await NodeHelpers.ensure_ready(self)
		speaker_field.value = value


static func create() -> LineEditor:
	return preload("res://addons/stageplay/line_editor.tscn").instantiate()


func unpack(unpacker: Unpacker) -> void:
	speaker = unpacker.at("speaker").string()
	for directive in unpacker.at("directives").array():
		var dialog_text := directive.at("dialog").string()
		if dialog_text:
			directives.add_child(_add_dialog_directive_editor(dialog_text))


func _add_dialog_directive_editor(text := "") -> DialogDirectiveEditor:
	var editor := DialogDirectiveEditor.create(text)
	editor.gui_input.connect(_on_directive_editor_gui_input.bind(editor))
	return editor


func _on_directive_editor_gui_input(event: InputEvent, editor: DialogDirectiveEditor) -> void:
	if event is InputEventKey and event.is_pressed() and event.keycode in [KEY_ENTER, KEY_KP_ENTER]:
		get_viewport().set_input_as_handled()
		await get_tree().process_frame

		var sibling := _add_dialog_directive_editor()
		editor.add_sibling(sibling)
		sibling.grab_focus()


func _on_add_directive_button_pressed() -> void:
	var editor := _add_dialog_directive_editor()
	directives.add_child(editor)
	editor.grab_focus()


func _on_speaker_field_submitted() -> void:
	var editor := _add_dialog_directive_editor()
	directives.add_child(editor)
	directives.move_child(editor, 0)
	editor.grab_focus()
