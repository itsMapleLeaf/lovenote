@tool
class_name TimelinePlayer
extends Node

@export_multiline var source: String:
	set(value):
		source = value
		if source:
			timeline = Timeline.new(source)

@export var preview_position: int = -1:
	set(value):
		preview_position = clampi(value, -1, timeline.sequence.size() - 1)
		await _ensure_ready()
		if not timeline:
			return
		_apply_current_snapshot()

var timeline: Timeline:
	set(value):
		timeline = value
		await _ensure_ready()
		if not timeline:
			return
		_apply_current_snapshot()

var timeline_position := 0
var line_position := 0

@onready var stage := %Stage as Stage


func _process(_delta: float) -> void:
	if not timeline:
		return

	if stage.is_running_command():
		return

	var line := timeline.sequence[clampi(timeline_position, 0, timeline.sequence.size() - 1)]

	while line_position < line.directives.size():
		stage.run_command(line.directives[clampi(line_position, 0, line.directives.size() - 1)])
		line_position += 1
		if stage.is_running_command():
			break


func _apply_current_snapshot() -> void:
	var snapshot := (
		timeline.sequence[timeline_position].snapshot
		if timeline_position > -1
		else StageSnapshot.new()
	)
	stage.apply(snapshot)


func _ensure_ready() -> void:
	if not is_node_ready():
		await ready
