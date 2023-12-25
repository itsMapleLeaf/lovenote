extends Node

var stage_sequence: Array[StageLine] = _create_stage_sequence(
	"""
	Hello world.
	[speaker:Ryder] [enter:ryder,to=0.35,from=-0.2,duration=1] This is some text. \
	[wait:1.0] [background:office_interior.png] This is some more text.
	[speaker:Note] [enter:note,to=0.65,from=0.2,duration=1] Say what? [wait:1.0] That's kinda rad.
	[speaker:Note] [leave:note,by=0.2,duration=1] aight bye
	[speaker:Ryder] :(
	"""
)

var stage_sequence_position: int = -1:
	set(value):
		stage_sequence_position = clampi(value, -1, stage_sequence.size() - 1)
		var snapshot := (
			stage_sequence[stage_sequence_position].snapshot
			if stage_sequence_position > -1
			else StageState.new()
		)
		_apply_snapshot(snapshot)

@onready var background := %Background as TextureRect
@onready var dialog_ui := %DialogUI as DialogUI
@onready var characters := %Characters as Node


func _ready() -> void:
	background.modulate = Color.TRANSPARENT
	dialog_ui.clear()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("dialog_next"):
		stage_sequence_position += 1
	elif event.is_action_pressed("dialog_prev"):
		stage_sequence_position -= 1


func _apply_snapshot(snapshot: StageState) -> void:
	if snapshot.background.is_empty():
		background.modulate.a = 0
	else:
		background.texture = load("res://content/backgrounds/" + snapshot.background)
		background.modulate.a = 1

	dialog_ui.speaker = snapshot.speaker
	dialog_ui.text = snapshot.text

	for character in characters.get_children():
		character.queue_free()

	for character_state in snapshot.characters:
		var scene_path := "res://content/characters/%s.tscn" % character_state.name
		var scene := load(scene_path) as PackedScene
		var character := scene.instantiate() as Character
		character.stage_position = character_state.stage_position
		characters.add_child(character)


func _create_stage_sequence(timeline_source: String) -> Array[StageLine]:
	var sequence: Array[StageLine] = []

	var text_and_directive_regex := RegEx.create_from_string(
		r"(?<text>[^\[]+)?(?:\[(?:(?<directive_name>[a-z_]+)):(?<directive_value>.+?)\])?"
	)

	var state: StageState
	for line in timeline_source.split("\n", false):
		line = line.strip_edges()

		if line.is_empty():
			continue

		state = state.duplicate(true) if state else StageState.new()
		state.speaker = ""

		var parts: Array[StageLinePart] = []

		for match in text_and_directive_regex.search_all(line):
			var text := match.get_string("text")
			text = text.strip_edges() if text else ""
			if not text.is_empty():
				parts.append(TextPart.new(text))

			var directive_name := match.get_string("directive_name")
			var directive_value := match.get_string("directive_value")
			if directive_name and directive_value:
				parts.append(DirectivePart.new(directive_name, directive_value))

		state.apply_parts(parts)
		sequence.append(StageLine.new(parts, state))
		print(StageLine.new(parts, state))

	print_rich(
		(
			"[color=gray]Loaded stage sequence with [color=white]%d[/color] lines[/color]"
			% sequence.size()
		)
	)

	return sequence


class StageState:
	extends Resource

	@export var background: String = ""
	@export var speaker: String = ""
	@export var text: String = ""
	@export var characters: Array[CharacterState] = []

	func _to_string() -> String:
		var data := {
			"speaker": speaker,
			"text": text,
			"background": background,
			"characters": characters,
		}
		return "StageState(%s)" % data

	func apply_parts(parts: Array[StageLinePart]) -> void:
		var text_parts := PackedStringArray()

		for part in parts:
			if part is TextPart:
				text_parts.append(part.text)
			elif part is DirectivePart:
				_apply_directive_part(part)

		text = " ".join(text_parts)

		var extra_white_space := RegEx.create_from_string(r"\s+")
		text = extra_white_space.sub(text, " ", true)

	func _apply_directive_part(part: DirectivePart) -> void:
		match part.name:
			"speaker":
				speaker = part.value
			"background":
				background = part.value
			"enter":
				var name := part.get_required_arg(0)
				var position := part.get_required_arg("to").to_float()
				characters.append(CharacterState.new(name, position))
			"leave":
				for index in characters.size():
					var character := characters[index]
					if character.name == part.args[0]:
						characters.remove_at(index)
						break


class CharacterState:
	extends Resource
	var name: String
	var stage_position: float

	func _init(name: String, stage_position: float) -> void:
		self.name = name
		self.stage_position = stage_position

	func _to_string() -> String:
		var data := {
			"name": name,
			"stage_position": stage_position,
		}
		return "CharacterState(%s)" % data


class StageLine:
	var parts: Array[StageLinePart]
	var snapshot: StageState

	func _init(parts: Array[StageLinePart], snapshot: StageState) -> void:
		self.parts = parts
		self.snapshot = snapshot

	func _to_string() -> String:
		var data := {
			"parts": parts,
			"snapshot": snapshot,
		}
		return "StageLine(%s)" % data


class StageLinePart:
	pass


class TextPart:
	extends StageLinePart
	var text: String

	func _init(text: String) -> void:
		self.text = text

	func _to_string() -> String:
		return "TextPart(%s)" % text


class DirectivePart:
	extends StageLinePart

	var name: String
	var value: String
	var args: Dictionary = {}

	func _init(name: String, value: String) -> void:
		self.name = name
		self.value = value

		var positional_arg_index := 0
		for value_part in value.split(",", false):
			var named_arg_parts := value_part.split("=", false)
			if named_arg_parts.size() == 2:
				var arg_name := named_arg_parts[0].strip_edges()
				var arg_value := named_arg_parts[1].strip_edges()
				args[arg_name] = arg_value
			else:
				args[positional_arg_index] = value_part.strip_edges()
				positional_arg_index += 1

	func get_required_arg(key: Variant) -> String:
		if not args.has(key):
			var message := (
				"Missing required argument '%s' for directive [%s:%s]" % [key, name, value]
			)
			push_error(message)
		return args[key]

	func _to_string() -> String:
		var data := {
			"name": name,
			"args": args,
		}
		return "DirectivePart(%s)" % data
