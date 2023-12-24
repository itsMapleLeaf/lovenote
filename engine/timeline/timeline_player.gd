@tool
class_name TimelinePlayer
extends Node

@export_file("*.md") var timeline_path: String:
	set(value):
		timeline_path = value

		if not timeline_path:
			return

		if not FileAccess.file_exists(timeline_path):
			push_error("Timeline file %s does not exist" % timeline_path)
			return

		_timeline = Timeline.new(FileAccess.get_file_as_string(timeline_path))

@export_range(0, 999999) var preview_timeline_position: int = 0:
	set(target_position):
		if not _timeline:
			push_warning("No _timeline loaded")
			preview_timeline_position = maxi(target_position, 0)
			return

		preview_timeline_position = clampi(target_position, 0, _timeline.lines.size() - 1)

		if not Engine.is_editor_hint():
			return

		if _current_line_index == preview_timeline_position:
			return

		_current_line_index = preview_timeline_position
		_current_line_part_index = 0
		_play_current_line()

var _timeline: Timeline
var _current_line_index := 0
var _current_line_part_index := 0

@onready var _background := %Background as Background


func _ready() -> void:
	if not _timeline:
		return

	_play_current_line()


func _play_current_line() -> void:
	var state := _get_current_part_state()
	if state.background:
		_background.transition_to_background(load("res://content/backgrounds/" + state.background))


# func _unhandled_input(event: InputEvent) -> void:
# 	if event.is_action_pressed("dialog_advance"):
# 		_get_current_part_state()


func _get_current_part_state(state := TimelineSceneState.new()) -> TimelineSceneState:
	if _current_line_index >= _timeline.lines.size():
		return state

	var line: DialogLine = _timeline.lines[_current_line_index]

	if _current_line_part_index >= line.parts.size():
		return state

	var part: DialogLine.DialogLinePart = line.parts[_current_line_part_index]

	if part is DialogLine.TextPart:
		pass

	if part is DialogLine.DirectivePart:
		if part.name == "set_background":
			state.background = part.value
			return _get_next_part_state(state)

	return state


func _get_next_part_state(state: TimelineSceneState) -> TimelineSceneState:
	_current_line_part_index += 1
	return _get_current_part_state(state)


class TimelineSceneState:
	var background: String
