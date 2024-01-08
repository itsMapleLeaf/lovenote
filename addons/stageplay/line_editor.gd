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


func unpack(data: LineData) -> void:
	speaker = data.speaker
	for directive in data.directives:
		directives.add_child(_add_dialog_directive_editor(directive.dialog))


func pack() -> LineData:
	var data := LineData.new(speaker, [])
	for directive: DialogDirectiveEditor in directives.get_children():
		data.directives.append(directive.pack())
	return data


func _add_dialog_directive_editor(text := "") -> DialogDirectiveEditor:
	var editor := DialogDirectiveEditor.create(text)
	editor.gui_input.connect(_on_directive_editor_gui_input.bind(editor))
	return editor


func _on_directive_editor_gui_input(event: InputEvent, editor: DialogDirectiveEditor) -> void:
	if event is InputEventKey and event.is_pressed() and (event as InputEventKey).keycode in [KEY_ENTER, KEY_KP_ENTER]:
		await NodeHelpers.handle_input_deferred(self)

		var line := editor.get_caret_line()
		var column := editor.get_caret_column()
		var last_line := editor.get_line_count() - 1
		var last_column := editor.get_line(last_line).length()

		editor.begin_complex_operation()
		editor.select(line, column, last_line, last_column)
		var moved_text := editor.get_selected_text()
		editor.delete_selection()
		editor.end_complex_operation()

		var index := editor.get_index()
		var sibling: Node
		if index < directives.get_child_count() - 1:
			sibling = directives.get_child(index + 1)

		if not (sibling is DialogDirectiveEditor and (sibling as DialogDirectiveEditor).text == ""):
			sibling = _add_dialog_directive_editor()
			editor.add_sibling(sibling)

		var sibling_editor := sibling as DialogDirectiveEditor
		sibling_editor.grab_focus()
		sibling_editor.insert_text_at_caret(moved_text)
		sibling_editor.set_caret_line(0)
		sibling_editor.set_caret_column(0)

	if event is InputEventKey \
	and event.is_pressed() \
	and (event as InputEventKey).keycode == KEY_BACKSPACE \
	and NodeHelpers.is_text_edit_at_start(editor):
		await NodeHelpers.handle_input_deferred(self)

		var previous := editor.find_prev_valid_focus() as DialogDirectiveEditor
		if previous:
			var last_line := previous.get_line_count() - 1
			var last_column := previous.get_line(last_line).length()

			previous.text += editor.text
			previous.grab_focus()
			previous.set_caret_column(last_column)
			previous.set_caret_line(last_line)

			editor.queue_free()

	if event is InputEventKey \
	and event.is_pressed() \
	and (event as InputEventKey).keycode == KEY_DELETE \
	and NodeHelpers.is_text_edit_at_end(editor):
		var index := editor.get_index()
		if index < directives.get_child_count() - 1:
			var sibling := directives.get_child(index + 1) as DialogDirectiveEditor
			if sibling:
				NodeHelpers.handle_input_deferred(self)
				var column := editor.get_caret_column()
				editor.text += sibling.text
				editor.set_caret_column(column)
				sibling.queue_free()


func _on_add_directive_button_pressed() -> void:
	var editor := _add_dialog_directive_editor()
	directives.add_child(editor)
	editor.grab_focus()


func _on_speaker_field_submitted() -> void:
	var editor := _add_dialog_directive_editor()
	directives.add_child(editor)
	directives.move_child(editor, 0)
	editor.grab_focus()
