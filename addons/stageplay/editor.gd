@tool
class_name StagePlayEditor
extends Node

const NodeHelpers := preload("res://addons/stageplay/node_helpers.gd")

@onready var lines: Control = %Lines
@onready var lines_container: ScrollContainer = %LinesContainer


static func create() -> StagePlayEditor:
	return preload("res://addons/stageplay/editor.tscn").instantiate()


func unpack(unpacker: Unpacker) -> void:
	NodeHelpers.remove_all_children(lines)
	for item in unpacker.at("lines").array():
		_add_line().unpack(item)


func _unpack_from_template() -> void:
	unpack(Unpacker.from(load("res://addons/stageplay/template.gd").get_template_data()))


func _add_line() -> LineEditor:
	var line := LineEditor.create()
	lines.add_child(line)
	return line


func _ready() -> void:
	_setup_new_menu()
	_unpack_from_template()


func _setup_new_menu() -> void:
	var items := [
		{
			text = "Blank",
			action = func(): unpack(Unpacker.from({ lines = [] })),
		},
		{
			text = "From Template",
			action = _unpack_from_template,
		},
	]

	var popup: PopupMenu = %NewMenu.get_popup()

	for index in popup.get_item_count():
		popup.remove_item(0)

	for item in items:
		popup.add_item(item["text"])

	popup.index_pressed.connect(
		func (index: int) -> void:
			items[index]["action"].call()
	)


func _on_add_line_button_pressed() -> void:
	_add_line().speaker_field.input_node.grab_focus()
