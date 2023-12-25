class_name Timeline

var sequence: Array[StageLine] = []

var text_and_directive_regex := RegEx.create_from_string(
	r"(?<text>[^\[]+)?(?:\[(?:(?<directive_name>[a-z_]+)):(?<directive_value>.+?)\])?"
)


func _init(timeline_source: String) -> void:
	sequence.clear()

	var snapshot := StageSnapshot.new()

	for line_source in timeline_source.split("\n", false):
		line_source = line_source.strip_edges()

		if line_source.is_empty():
			continue

		var commands: Array[StageCommand] = []

		for match in text_and_directive_regex.search_all(line_source):
			var text := match.get_string("text")
			text = text.strip_edges() if text else ""
			if not text.is_empty():
				commands.append(StageCommand.new("dialog", text))

			var directive_name := match.get_string("directive_name")
			var directive_value := match.get_string("directive_value")
			if directive_name and directive_value:
				commands.append(StageCommand.new(directive_name, directive_value))

		var line := StageLine.new(commands, snapshot)
		snapshot = line.snapshot
		sequence.append(line)

	print_rich(
		(
			"[color=gray]Loaded stage sequence with [color=white]%d[/color] lines[/color]"
			% sequence.size()
		)
	)
