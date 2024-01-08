@tool


static func remove_all_children(node: Node) -> void:
	for child in node.get_children():
		child.queue_free()


static func ensure_ready(node: Node) -> void:
	if not node.is_node_ready(): await node.ready
