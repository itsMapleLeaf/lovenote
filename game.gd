extends Control

var stage_sequence: Array[StageLine] = _create_stage_sequence(
	"""
	Hello world.
	[speaker:Ryder] This is some text. [wait:1.0] [background:office_interior.png] \
	This is some more text.
	[speaker:Note] Say what? [wait:1.0] That's kinda rad.
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

		state = state.duplicate() if state else StageState.new()
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

	func _to_string() -> String:
		var data := {
			"speaker": speaker,
			"text": text,
			"background": background,
		}
		return "StageState(%s)" % data

	func apply_parts(parts: Array[StageLinePart]) -> void:
		var text_parts := PackedStringArray()
		for part in parts:
			if part is TextPart:
				text_parts.append(part.text)
			elif part is BackgroundPart:
				background = part.background

		text = " ".join(text_parts)

		var extra_white_space := RegEx.create_from_string(r"\s+")
		text = extra_white_space.sub(text, " ", true)


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
