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
			_add_dialog_directive_editor(dialog_text)


func _add_dialog_directive_editor(text := "") -> DialogDirectiveEditor:
	var editor := DialogDirectiveEditor.create(text)
	directives.add_child(editor)
	return editor



func _on_add_directive_button_pressed() -> void:
	_add_dialog_directive_editor()
