@tool


static func remove_all_children(node: Node) -> void:
	for child in node.get_children():
		child.queue_free()


static func ensure_ready(node: Node) -> void:
	if not node.is_node_ready(): await node.ready


static func handle_input_deferred(node: Node) -> void:
	node.get_viewport().set_input_as_handled()
	await node.get_tree().process_frame


static func is_text_edit_at_start(node: TextEdit) -> bool:
	var caret_line := node.get_caret_line()
	var caret_column := node.get_caret_column()
	var caret_wrap_index := node.get_caret_wrap_index()
	return caret_line == 0 and caret_column == 0 and caret_wrap_index == 0


static func is_text_edit_at_end(node: TextEdit) -> bool:
	var caret_line := node.get_caret_line()
	var caret_wrap_index := node.get_caret_wrap_index()
	var caret_column := node.get_caret_column()
	var last_line_index := node.get_line_count() - 1
	var last_wrap_index := node.get_line_wrap_count(last_line_index)
	var last_column := node.get_line(last_line_index).length()
	return caret_line == last_line_index \
		and caret_wrap_index == last_wrap_index \
		and caret_column == last_column
