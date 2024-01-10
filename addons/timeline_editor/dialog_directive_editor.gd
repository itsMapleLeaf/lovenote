@tool
class_name DialogDirectiveEditor
extends TextEdit


static func create(instance_text := "") -> DialogDirectiveEditor:
	var instance: DialogDirectiveEditor = (
		preload("res://addons/timeline_editor/dialog_directive_editor.tscn").instantiate()
	)
	instance.text = instance_text
	return instance


func pack() -> DirectiveData:
	var data := DirectiveData.new()
	data.dialog = text
	return data


func is_at_start() -> bool:
	var caret_line := get_caret_line()
	var caret_column := get_caret_column()
	var caret_wrap_index := get_caret_wrap_index()
	return caret_line == 0 and caret_column == 0 and caret_wrap_index == 0


func is_at_end() -> bool:
	var caret_line := get_caret_line()
	var caret_wrap_index := get_caret_wrap_index()
	var caret_column := get_caret_column()
	var last_line_index := get_line_count() - 1
	var last_wrap_index := get_line_wrap_count(last_line_index)
	var last_column := get_line(last_line_index).length()
	return (
		caret_line == last_line_index
		and caret_wrap_index == last_wrap_index
		and caret_column == last_column
	)
