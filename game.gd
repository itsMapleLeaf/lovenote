extends Node

var stage_sequence: Array[StageLine] = _create_stage_sequence(
	"""
	Hello world.
	[speaker:Ryder] [enter:ryder,to=0.35,from=-0.2,duration=1] This is some text. \
	[wait:1.0] [background:office_interior.png] \
	This is some more text.
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
			if directive_name == "speaker":
				state.speaker = directive_value
			elif directive_name == "background":
				parts.append(BackgroundPart.new(directive_value))
			elif directive_name == "wait":
				parts.append(WaitPart.new(float(directive_value)))
			elif directive_name == "enter":
				var params := DirectiveParams.from_string(directive_name, directive_value)
				parts.append(EnterPart.from_directive_params(params))
			elif directive_name == "leave":
				var params := DirectiveParams.from_string(directive_name, directive_value)
				parts.append(LeavePart.from_directive_params(params))

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


class DirectiveParams:
	var directive_name: String
	var directive_value: String
	var values: Dictionary = {}

	func _init(directive_name: String, directive_value: String) -> void:
		self.directive_name = directive_name
		self.directive_value = directive_value

	static func from_string(directive_name: String, directive_value: String) -> DirectiveParams:
		var params := DirectiveParams.new(directive_name, directive_value)
		var positional_value_index := 0
		for positional_value in directive_value.split(",", false):
			var parts := positional_value.split("=", false)
			if parts.size() == 2:
				params.values[parts[0].strip_edges()] = parts[1].strip_edges()
			else:
				params.values[positional_value_index] = positional_value.strip_edges()
				positional_value_index += 1
		return params

	func get_required(key: Variant) -> String:
		var value := values[key] as String
		if not value:
			push_error(
				"invalid directive [%s:%s]: %s is required" % [directive_name, directive_value, key]
			)
		return value


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
			elif part is BackgroundPart:
				background = part.background
			elif part is EnterPart:
				characters.append(CharacterState.new(part.character_name, part.to_position))
			elif part is LeavePart:
				for index in range(characters.size() - 1, -1, -1):
					var character := characters[index]
					if character.name == part.character_name:
						characters.remove_at(index)
						break

		text = " ".join(text_parts)

		var extra_white_space := RegEx.create_from_string(r"\s+")
		text = extra_white_space.sub(text, " ", true)


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


class BackgroundPart:
	extends StageLinePart
	var background: String

	func _init(background: String) -> void:
		self.background = background

	func _to_string() -> String:
		return "BackgroundPart(%s)" % background


class WaitPart:
	extends StageLinePart
	var wait_duration: float

	func _init(wait_duration: float) -> void:
		self.wait_duration = wait_duration

	func _to_string() -> String:
		return "WaitPart(%s)" % wait_duration


class EnterPart:
	extends StageLinePart

	var character_name: String = ""
	var from_position: float = 0
	var to_position: float = 0
	var duration: float = 0

	func _to_string() -> String:
		var data := {
			"character_name": character_name,
			"from_position": from_position,
			"to_position": to_position,
			"duration": duration,
		}
		return "EnterPart(%s)" % data

	static func from_directive_params(params: DirectiveParams) -> EnterPart:
		var part := EnterPart.new()
		part.character_name = params.get_required(0)
		part.from_position = params.get_required("from").to_float()
		part.to_position = params.get_required("to").to_float()
		part.duration = params.get_required("duration").to_float()
		return part


class LeavePart:
	extends StageLinePart

	var character_name: String = ""
	var by_position: float = 0
	var duration: float = 0

	func _to_string() -> String:
		var data := {
			"character_name": character_name,
			"by_position": by_position,
			"duration": duration,
		}
		return "EnterPart(%s)" % data

	static func from_directive_params(params: DirectiveParams) -> LeavePart:
		var part := LeavePart.new()
		part.character_name = params.get_required(0)
		part.by_position = params.get_required("by").to_float()
		part.duration = params.get_required("duration").to_float()
		return part
