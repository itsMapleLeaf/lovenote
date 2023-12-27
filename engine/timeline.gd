class_name Timeline

var lines: Array[StageLine] = []
var current_line_index := 0


func _init(source: String) -> void:
	var state := StageState.new()

	for source_line in source.split("\n", false):
		source_line = source_line.strip_edges()

		if source_line.is_empty():
			continue

		var line := StageLine.new()

		var text_and_directive_regex := RegEx.create_from_string(
			r"(?<text>[^\[]+)?(?:\[(?:(?<directive_name>[a-z_]+)):(?<directive_value>.+?)\])?"
		)

		for match in text_and_directive_regex.search_all(source_line):
			var text := match.get_string("text")
			if text:
				line.directives.append(DialogDirective.new(text))

			var directive_name := match.get_string("directive_name")
			var directive_value := match.get_string("directive_value")
			if directive_name and directive_value:
				var args := DirectiveArgs.new(directive_name, directive_value)
				match directive_name:
					"speaker":
						line.directives.append(SpeakerDirective.new(directive_value))
					"background":
						line.directives.append(BackgroundDirective.new(directive_value))
						state.background = directive_value
					"wait":
						var duration := args.get_required_arg(0).to_float()
						line.directives.append(WaitDirective.new(duration))
					"enter":
						var character_name := args.get_required_arg(0)
						var to_position := args.get_required_arg("to").to_float()
						var from_position := args.get_required_arg("from").to_float()
						var duration := args.get_required_arg("duration").to_float()
						line.directives.append(
							EnterDirective.new(character_name, to_position, from_position, duration)
						)
						state.characters.append(CharacterState.new(character_name, from_position))
					"leave":
						var character_name := args.get_required_arg(0)
						var by_position := args.get_required_arg("by").to_float()
						var duration := args.get_required_arg("duration").to_float()

						line.directives.append(
							LeaveDirective.new(character_name, by_position, duration)
						)

						state.remove_character(character_name)
					_:
						push_error("Unknown directive: [%s:%s]" % [directive_name, directive_value])

		line.end_state = state.create_snapshot()
		lines.append(line)


func process(stage: Stage, delta: float) -> void:
	lines[current_line_index].process(stage, delta)


func advance(stage: Stage) -> void:
	if lines[current_line_index].is_playing(stage):
		lines[current_line_index].skip(stage)
	elif current_line_index < lines.size() - 1:
		current_line_index += 1
		lines[current_line_index].reset(stage)


func is_ready_to_advance(stage: Stage) -> bool:
	return not lines[current_line_index].is_playing(stage)


class DirectiveArgs:
	var directive_name: String
	var directive_value: String
	var args: Dictionary = {}

	func _init(directive_name: String, directive_value: String) -> void:
		self.directive_name = directive_name
		self.directive_value = directive_value

		var position := 0
		for value_part in directive_value.split(",", false):
			var arg_parts := value_part.split("=")
			if arg_parts.size() == 2:
				var arg_name := arg_parts[0]
				var arg_value := arg_parts[1]
				args[arg_name] = arg_value
			else:
				args[position] = value_part
				position += 1

	func get_required_arg(name: Variant) -> String:
		if not args.has(name):
			push_error(
				(
					'Missing required argument "%s" in directive [%s:%s]'
					% [name, directive_name, directive_value]
				)
			)
			return ""
		return args[name]


class StageState:
	var background: String = ""
	var characters: Array[CharacterState] = []

	func create_snapshot() -> StageState:
		var snapshot := StageState.new()
		snapshot.background = background
		for character in characters:
			snapshot.characters.append(character.create_snapshot())
		return snapshot

	func remove_character(name: String) -> void:
		characters = characters.filter(
			func(character: CharacterState) -> bool: return character.name != name
		)


class CharacterState:
	var name := ""
	var position := 0.0

	func _init(name: String, position: float) -> void:
		self.name = name
		self.position = position

	func create_snapshot() -> CharacterState:
		return CharacterState.new(name, position)


class StageLine:
	var end_state: StageState
	var directives: Array[StageDirective] = []
	var current_directive_index := 0

	func reset(stage: Stage) -> void:
		current_directive_index = 0
		for directive in directives:
			directive.reset()
		stage.dialog.reset()

	func process(stage: Stage, delta: float) -> void:
		while current_directive_index < directives.size():
			var directive := directives[current_directive_index]
			directive.process(stage, delta)
			if directive.is_playing(stage):
				break
			else:
				current_directive_index += 1

	func is_playing(_stage: Stage) -> bool:
		return current_directive_index < directives.size()

	func skip(stage: Stage) -> void:
		while current_directive_index < directives.size():
			directives[current_directive_index].skip(stage)
			current_directive_index += 1


class StageDirective:
	func reset() -> void:
		pass

	func process(_stage: Stage, _delta: float) -> void:
		pass

	func is_playing(_stage: Stage) -> bool:
		return false

	func skip(_stage: Stage) -> void:
		pass


class DialogDirective:
	extends StageDirective

	var text: String
	var started := false

	func _init(text: String) -> void:
		self.text = _simple_markdown_to_bbcode(text)

	func _simple_markdown_to_bbcode(text: String) -> String:
		# translates markdown bold and italics to bbcode
		var bold_italics_regex := RegEx.create_from_string(r"(\*\*\*|___)([^\1]*)\1")
		var bold_regex := RegEx.create_from_string(r"(\*\*|__)([^\1]*)\1")
		var italics_regex := RegEx.create_from_string(r"([*_])([^\1]*)\1")

		text = bold_italics_regex.sub(text, "[b][i]$1$2[/i][/b]", true)
		text = bold_regex.sub(text, "[b]$1$2[/b]", true)
		text = italics_regex.sub(text, "[i]$2[/i]", true)

		return text

	func reset() -> void:
		started = false

	func process(stage: Stage, _delta: float) -> void:
		if not started:
			stage.dialog.text += " " + text
			started = true

	func is_playing(stage: Stage) -> bool:
		return stage.dialog.is_playing()

	func skip(stage: Stage) -> void:
		process(stage, 0)
		stage.dialog.skip()


class SpeakerDirective:
	extends StageDirective

	var speaker_name: String

	func _init(speaker_name: String) -> void:
		self.speaker_name = speaker_name

	func process(stage: Stage, _delta: float) -> void:
		stage.dialog.speaker = speaker_name


class BackgroundDirective:
	extends StageDirective

	var background: Texture2D

	func _init(file: String) -> void:
		background = load("res://content/backgrounds/" + file) as Texture2D
		if not background:
			push_error("Background not found: " + file)

	func process(stage: Stage, _delta: float) -> void:
		stage.set_background(background)

	func skip(stage: Stage) -> void:
		process(stage, 0)


class WaitDirective:
	extends StageDirective

	var duration: float
	var remaining: float

	func _init(duration: float) -> void:
		self.duration = duration
		self.remaining = duration

	func reset() -> void:
		remaining = duration

	func process(_stage: Stage, delta: float) -> void:
		remaining -= delta

	func skip(_stage: Stage) -> void:
		remaining = 0

	func is_playing(_stage: Stage) -> bool:
		return remaining > 0


class EnterDirective:
	extends StageDirective

	var character_name: String
	var to_position: float
	var from_position: float
	var duration: float

	func _init(
		character_name: String, to_position: float, from_position: float, duration: float
	) -> void:
		self.character_name = character_name
		self.to_position = to_position
		self.from_position = from_position
		self.duration = duration

	func process(stage: Stage, _delta: float) -> void:
		stage.enter_character(character_name, from_position, to_position, duration)

	func skip(stage: Stage) -> void:
		stage.enter_character(character_name, from_position, to_position, 0)


class LeaveDirective:
	extends StageDirective

	var character_name: String
	var by_position: float
	var duration: float

	func _init(character_name: String, by_position: float, duration: float) -> void:
		self.character_name = character_name
		self.by_position = by_position
		self.duration = duration

	func process(stage: Stage, _delta: float) -> void:
		stage.leave_character(character_name, by_position, duration)

	func skip(stage: Stage) -> void:
		stage.leave_character(character_name, by_position, 0)
