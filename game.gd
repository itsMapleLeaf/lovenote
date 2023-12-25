@tool
extends Node

@export var timeline_position: int = -1:
	set(value):
		timeline_position = clampi(value, -1, timeline.sequence.size() - 1)
		var snapshot := (
			timeline.sequence[timeline_position].snapshot
			if timeline_position > -1
			else StageState.new()
		)
		stage.apply_snapshot(snapshot)

var timeline_source := """
Hello world.
[speaker:Ryder] [enter:ryder,to=0.35,from=-0.2,duration=1] This is some text. \
[wait:1.0] [background:office_interior.png] This is some more text.
[speaker:Note] [enter:note,to=0.65,from=0.2,duration=1] Say what? [wait:1.0] That's kinda rad.
[speaker:Note] [leave:note,by=0.2,duration=1] aight bye
[speaker:Ryder] :(
"""

var timeline := Timeline.new(timeline_source)

@onready var stage := %Stage as Stage


func _ready() -> void:
	stage.apply_snapshot(StageState.new())


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("dialog_next"):
		timeline_position += 1
	elif event.is_action_pressed("dialog_prev"):
		timeline_position -= 1
