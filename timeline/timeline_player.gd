@tool
extends Node
class_name TimelinePlayer

## An animation player containing all of the animations for the timeline
@export var animation_player: AnimationPlayer

## The path to the timeline file
@export_file("*.md") var timeline_file: String:
	set(value):
		timeline_file = value
		timeline = Timeline.from_file(value)

## The current position in the timeline for previewing in the editor
@export_range(0, 999999) var preview_position: int:
	set(value):
		preview_position = value
		if not Engine.is_editor_hint(): return
		if not is_node_ready(): await ready
		_seek_to(value)

var current_position := 0

var timeline: Timeline
var queued_parts: Array[Timeline.DialogPart] = []
var delay_time := 0.0

@onready var dialog_ui: DialogUI = %DialogUI

func _ready() -> void:
	# some of the children aren't ready when this is called for some reason
	_seek_to.call_deferred(0)

func _process(delta: float) -> void:
	dialog_ui.advance_indicator_visible = _ready_to_advance()

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
		if _ready_to_advance():
			_seek_to(current_position + 1)
		else:
			_complete_line()

	if event.is_action_pressed("dialog_prev"):
		_seek_to(current_position - 1)

	if event.is_action_pressed("dialog_next"):
		_seek_to(current_position + 1)

func _seek_to(position: int) -> void:
	var previous_position := current_position
	current_position = position

	# when seeking forward, set interim animations to their end state
	if current_position > previous_position:
		for interim_position in range(previous_position, current_position):
			var line := timeline.line_at(interim_position)
			for animation_name in line.animations:
				Helpers.seek_animation(animation_player, animation_name, animation_player.current_animation_length)

	# when seeking backward, set interim animations to their start state
	# but also reset the current animations
	if current_position < previous_position:
		for interim_position in range(current_position, previous_position + 1):
			var line := timeline.line_at(interim_position)
			for animation_name in line.animations:
				Helpers.seek_animation(animation_player, animation_name, 0)

	var line := timeline.line_at(current_position)
	queued_parts = line.parts.duplicate()
	delay_time = 0
	dialog_ui.reset()

	if line.speaker:
		dialog_ui.set_speaker(line.speaker)

func _ready_to_advance() -> bool:
	return queued_parts.is_empty() and not dialog_ui.is_playing() and delay_time <= 0

func _complete_line() -> void:
	if animation_player.current_animation:
		animation_player.advance(animation_player.current_animation_length)

	for part in queued_parts:
		if part.animation_name:
			animation_player.current_animation = part.animation_name
			animation_player.seek(animation_player.current_animation_length, true, true)

	dialog_ui.complete(timeline.line_at(current_position).full_text)
	delay_time = 0
	queued_parts = []
