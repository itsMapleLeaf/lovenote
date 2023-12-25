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
		var snapshot := timeline.sequence[position].snapshot if position > -1 else StageState.new()
		stage.apply_snapshot(snapshot)

var timeline: Timeline

@onready var stage := %Stage as Stage
