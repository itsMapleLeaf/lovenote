class_name Timeline

var lines: Array[DialogLine]

func _init(lines: Array[DialogLine]) -> void:
	self.lines = lines

func line_at(position: int) -> DialogLine:
	return lines[position]

static func from_file(file_path: String) -> Timeline:
	var start_time := Time.get_ticks_msec()

	var lines: Array[DialogLine] = []
	var line_number := 0
	var content := FileAccess.open(file_path, FileAccess.READ).get_as_text()
	var current_delay := 0.0
	var current_animations: Array[StringName] = []

	for line in content.split("\n"):
		if line.is_empty() or line.begins_with("#"): continue
		lines.append(DialogLine.new(line))

	print("Loaded timeline in %d ms" % (Time.get_ticks_msec() - start_time))

	return Timeline.new(lines)

class DialogLine:
	var parts: Array[DialogPart] = []
	var speaker: String

	func _init(line: String) -> void:
		var text_and_directive_regex := RegEx.create_from_string(
			# dear lord
			r"(?<text>[^\[]+)?(?:\[(?:(?<directive_name>[a-z]+):?)?(?<directive_value>.+?)\]\s*)?"
		)

		for match in text_and_directive_regex.search_all(line):
			var text := match.get_string("text")
			var directive_name := match.get_string("directive_name")
			var directive_value := match.get_string("directive_value")

			if text and not text.is_empty():
				parts.append(DialogPart.from_text(text))

			if directive_name and directive_value:
				parts.append(DialogPart.from_directive(directive_name, directive_value))
			elif directive_value:
				speaker = directive_value

class DialogPart:
	var text: String
	var animation_name: StringName
	var delay_duration: float

	static func from_text(text: String) -> DialogPart:
		var part := DialogPart.new()
		part.text = text
		return part

	static func from_directive(name: String, value: String) -> DialogPart:
		var part := DialogPart.new()
		match name:
			"animation": part.animation_name = value
			"delay": part.delay_duration = value.to_float()
		return part
