class_name Timeline

var lines: Array[DialogLine] = []


func _init(source: String) -> void:
	for line in source.split("\n", false):
		line = line.strip_edges()

		if line.is_empty():
			continue

		lines.append(DialogLine.new(line))


func _strip_edges(text: String) -> String:
	return text.strip_edges()


func _is_non_empty(text: String) -> bool:
	return not text.is_empty()
