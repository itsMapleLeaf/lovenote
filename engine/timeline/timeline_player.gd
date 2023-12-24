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

		timeline = Timeline.new(FileAccess.get_file_as_string(timeline_path))

@export_range(0, 999999) var preview_timeline_position: int = 0:
	set(target_position):
		if not timeline:
			push_warning("No timeline loaded")
			preview_timeline_position = maxi(target_position, 0)
			return

		preview_timeline_position = clampi(target_position, 0, timeline.lines.size() - 1)

		if not Engine.is_editor_hint():
			return

		if current_line_index == preview_timeline_position:
			return

		current_line_index = preview_timeline_position
		current_line_part_index = 0
		_process_current_part()

var timeline: Timeline
var current_line_index := 0
var current_line_part_index := 0

@onready var background := %Background as Background


func _ready() -> void:
	if not timeline:
		return
	_process_current_part()


# func _unhandled_input(event: InputEvent) -> void:
# 	if event.is_action_pressed("dialog_advance"):
# 		_process_current_part()


func _process_current_part() -> void:
	if current_line_index >= timeline.lines.size():
		return

	var line: DialogLine = timeline.lines[current_line_index]

	if current_line_part_index >= line.parts.size():
		return

	var part: DialogLine.DialogLinePart = line.parts[current_line_part_index]

	if part is DialogLine.TextPart:
		pass

	if part is DialogLine.DirectivePart:
		if part.name == "set_background":
			background.transition_to_background(load("res://content/backgrounds/" + part.value))
			return _process_next_part()


func _process_next_part() -> void:
	current_line_part_index += 1
	_process_current_part()
