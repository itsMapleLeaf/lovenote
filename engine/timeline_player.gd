class_name TimelinePlayer
extends Node

@export_multiline var timeline_source := ""
@export var current_line_index: int = 0

@onready var stage: Stage = %Stage
@onready var timeline := _load_timeline(timeline_source)
@onready var line_player := StageLinePlayer.new(timeline[0], stage)

func _process(delta: float) -> void:
	line_player._process(delta)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("dialog_advance"):
		_advance() if not line_player.is_playing() else _skip()


func _advance() -> void:
	if current_line_index >= timeline.size() - 1:
		return

	current_line_index += 1
	line_player = StageLinePlayer.new(timeline[current_line_index], stage)


func _skip() -> void:
	pass # todo


func _load_timeline(timeline_source: String) -> Array[StageLine]:
	var timeline: Array[StageLine] = []
	var state := StageState.new()

	for source_line in timeline_source.split("\n", false):
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

		line.snapshot = state.create_snapshot()
		timeline.append(line)

	return timeline


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
		var new_characters: Array[CharacterState] = []
		for character in characters:
			if character.name != name:
				new_characters.append(character)
		characters = new_characters


class CharacterState:
	var name := ""
	var position := 0.0

	func _init(name: String, position: float) -> void:
		self.name = name
		self.position = position

	func create_snapshot() -> CharacterState:
		return CharacterState.new(name, position)


class StageLine:
	var speaker: String = ""
	var directives: Array[StageDirective] = []
	var snapshot: StageState


class StageDirective:
	pass


class DialogDirective:
	extends StageDirective

	var dialog_text: String

	func _init(dialog_text: String) -> void:
		self.dialog_text = dialog_text


class SpeakerDirective:
	extends StageDirective

	var speaker_name: String

	func _init(speaker_name: String) -> void:
		self.speaker_name = speaker_name


class BackgroundDirective:
	extends StageDirective

	var background: Texture2D

	func _init(file: String) -> void:
		background = load("res://content/backgrounds/" + file) as Texture2D
		if not background:
			push_error("Background not found: " + file)


class WaitDirective:
	extends StageDirective

	var duration: float

	func _init(duration: float) -> void:
		self.duration = duration


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


class LeaveDirective:
	extends StageDirective

	var character_name: String
	var by_position: float
	var duration: float

	func _init(character_name: String, by_position: float, duration: float) -> void:
		self.character_name = character_name
		self.by_position = by_position
		self.duration = duration


class StageLinePlayer:
	var line: StageLine
	var stage: Stage
	var speaker := ""
	var text := ""
	var current_directive_index: int = 0
	var wait_time := 0.0

	func _init(line: StageLine, stage: Stage) -> void:
		self.line = line
		self.stage = stage

	func is_playing() -> bool:
		return not line.directives.is_empty() and current_directive_index < line.directives.size()

	func _process(delta: float) -> void:
		stage.dialog.speaker = speaker
		stage.dialog.text = text

		if wait_time > 0:
			wait_time -= delta
			return

		_process_current_directive()

	func _process_current_directive() -> void:
		if line.directives.is_empty():
			return

		if current_directive_index >= line.directives.size():
			return

		var directive := line.directives[current_directive_index]
		current_directive_index += 1

		var speaker_directive := directive as SpeakerDirective
		if speaker_directive:
			speaker = speaker_directive.speaker_name
			_process_current_directive()

		var dialog_directive := directive as DialogDirective
		if dialog_directive:
			text += " " + dialog_directive.dialog_text
			_process_current_directive()

		var background_directive := directive as BackgroundDirective
		if background_directive:
			stage.set_background( background_directive.background, )
			_process_current_directive()

		var wait_directive := directive as WaitDirective
		if wait_directive:
			wait_time += wait_directive.duration

		var enter_directive := directive as EnterDirective
		if enter_directive:
			stage.enter_character(
				enter_directive.character_name,
				enter_directive.from_position,
				enter_directive.to_position,
				enter_directive.duration
			)
			_process_current_directive()

		var leave_directive := directive as LeaveDirective
		if leave_directive:
			stage.leave_character(
				leave_directive.character_name,
				leave_directive.by_position,
				leave_directive.duration
			)
			_process_current_directive()
