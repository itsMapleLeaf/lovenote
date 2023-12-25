@tool
class_name TimelinePlayer
extends Node

@export_multiline var source: String:
	set(value):
		source = value
		if source:
			timeline = Timeline.new(source)

@export var position: int = -1:
	set(value):
		position = clampi(value, -1, timeline.sequence.size() - 1)
		if not timeline:
			return
		await _ensure_ready()
		_apply_current_snapshot()

var timeline: Timeline:
	set(value):
		timeline = value
		if not timeline:
			return
		await _ensure_ready()
		_apply_current_snapshot()

@onready var stage := %Stage as Stage


func _apply_current_snapshot() -> void:
	var snapshot := timeline.sequence[position].snapshot if position > -1 else StageSnapshot.new()
	stage.apply(snapshot)


func _ensure_ready() -> void:
	if not is_node_ready():
		await ready
