@tool
extends Node
class_name TimelinePlayer

## An animation player containing all of the animations for the timeline
@export var animation_player: AnimationPlayer

## The UI through which to play dialog
@export var dialog_ui: DialogUI

## The path to the timeline file
@export_file("*.md") var timeline_file: String:
	set(value):
		timeline_file = value
		timeline = Timeline.from_file(value)

## The current position in the timeline.
## Setting this will play the timeline event at that position.
@export_range(0, 999999) var current_position: int:
	set(value):
		current_position = clampi(value, 0, timeline.lines.size())

		# call play immediately in the editor,
		# but in game, only call after the node is ready
		if Engine.is_editor_hint() or is_node_ready():
			_play.call_deferred(current_position)

var timeline: Timeline
var queued_parts: Array[Timeline.DialogPart] = []
var delay_time := 0.0

func _ready() -> void:
	if not Engine.is_editor_hint():
		current_position = 0

func _process(delta: float) -> void:
	if dialog_ui.is_playing():
		return

	if delay_time > 0:
		delay_time -= delta
		return

	while queued_parts.size() > 0:
		var part := queued_parts.pop_front() as Timeline.DialogPart
		if part.animation_name:
			animation_player.play(part.animation_name)
		if part.text:
			dialog_ui.play_text(part.text)
			break
		if part.delay_duration:
			delay_time += part.delay_duration
			break

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("dialog_advance"):
		current_position += 1

func _play(position: int) -> void:
	var line := timeline.line_at(position)

	queued_parts = line.parts.duplicate()
	delay_time = 0

	dialog_ui.reset()
	if line.speaker:
		dialog_ui.set_speaker(line.speaker)
