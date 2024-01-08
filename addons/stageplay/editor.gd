@tool
class_name StagePlayEditor
extends Control

const NodeHelpers := preload("res://addons/stageplay/node_helpers.gd")

@onready var lines: Control = %Lines

static func create() -> StagePlayEditor:
	return preload("res://addons/stageplay/editor.tscn").instantiate()


func unpack(unpacker: Unpacker) -> void:
	NodeHelpers.remove_all_children(lines)
	for item in unpacker.at("lines").array():
		_add_line().unpack(item)


func _add_line() -> LineEditor:
	var line := LineEditor.create()
	lines.add_child(line)
	return line


func _on_add_line_button_pressed() -> void:
	_add_line().speaker_field.input_node.grab_focus()


func _on_new_from_template_button_pressed() -> void:
	unpack(Unpacker.from(load("res://addons/stageplay/template.gd").get_template_data()))
