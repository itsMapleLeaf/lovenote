@tool
class_name TimelineEditor
extends Control

const NodeHelpers := preload("res://addons/timeline_editor/node_helpers.gd")

@onready var lines: Control = %Lines
@onready var lines_container: ScrollContainer = %LinesContainer


static func create() -> TimelineEditor:
	return preload("res://addons/timeline_editor/timeline_editor.tscn").instantiate()


func unpack(data: TimelineData) -> void:
	NodeHelpers.remove_all_children(lines)
	for line_data in data.lines:
		_add_line().unpack(line_data)


func _unpack_from_template() -> void:
	unpack(preload("res://addons/timeline_editor/template.gd").get_template_data())


func _add_line() -> LineEditor:
	var line := LineEditor.create()
	lines.add_child(line)
	return line


func _ready() -> void:
	_setup_new_menu()
	_unpack_from_template()


func _setup_new_menu() -> void:
	var items: Array[Dictionary] = [
		{
			text = "Blank",
			action = func() -> void: unpack(TimelineData.new([])),
		},
		{
			text = "From Template",
			action = _unpack_from_template,
		},
	]

	var menu: MenuButton = %NewMenu
	var popup: PopupMenu = menu.get_popup()

	for index in popup.get_item_count():
		popup.remove_item(0)

	for item in items:
		popup.add_item(item.get("text") as String)

	var _error := popup.index_pressed.connect(
		func (index: int) -> void:
			var fn := items[index].get("action") as Callable
			if fn: fn.call()
	)


func _on_add_line_button_pressed() -> void:
	_add_line().speaker_field.input_node.grab_focus()


func _input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.is_pressed()): return

	var focus_owner := get_viewport().gui_get_focus_owner()
	if not lines.is_ancestor_of(focus_owner): return

	var focus_neighbor: Control

	if (event as InputEventKey).keycode == KEY_UP and (not focus_owner is TextEdit or _is_text_edit_at_top(focus_owner as TextEdit)):
		get_viewport().set_input_as_handled()
		await get_tree().process_frame

		var target := focus_owner.find_valid_focus_neighbor(SIDE_TOP)
		if lines.is_ancestor_of(target):
			focus_neighbor = target

	if (event as InputEventKey).keycode == KEY_DOWN and (not focus_owner is TextEdit or _is_text_edit_at_bottom(focus_owner as TextEdit)):
		get_viewport().set_input_as_handled()
		await get_tree().process_frame

		var target := focus_owner.find_valid_focus_neighbor(SIDE_BOTTOM)
		if lines.is_ancestor_of(target):
			focus_neighbor = focus_owner.find_valid_focus_neighbor(SIDE_BOTTOM)

	if (event as InputEventKey).keycode == KEY_TAB and focus_owner is TextEdit:
		get_viewport().set_input_as_handled()
		await get_tree().process_frame
		if (event as InputEventKey).shift_pressed:
			focus_neighbor = focus_owner.find_prev_valid_focus()
		else:
			focus_neighbor = focus_owner.find_next_valid_focus()

	if focus_neighbor:
		focus_neighbor.grab_focus()


func _is_text_edit_at_top(node: TextEdit) -> bool:
	var caret_line := node.get_caret_line()
	var caret_wrap_index := node.get_caret_wrap_index()
	return caret_line == 0 and caret_wrap_index == 0


func _is_text_edit_at_bottom(node: TextEdit) -> bool:
	var caret_line := node.get_caret_line()
	var caret_wrap_index := node.get_caret_wrap_index()
	var last_line_index := node.get_line_count() - 1
	var last_wrap_index := node.get_line_wrap_count(last_line_index)
	return caret_line == last_line_index and caret_wrap_index == last_wrap_index


func _on_save_button_pressed() -> void:
	var data := TimelineData.new([])
	for line: LineEditor in lines.get_children():
		data.lines.append(line.pack())
	var _error := ResourceSaver.save(data, "res://test_timeline.tres")


func _on_open_button_pressed() -> void:
	var data: TimelineData = ResourceLoader.load("res://test_timeline.tres")
	unpack(data)
