class_name TimelinePlayer
extends Node

@export_multiline var timeline_source := ""

@onready var timeline := Timeline.new(timeline_source)
@onready var stage: Stage = %Stage


func _process(delta: float) -> void:
	timeline.process(stage, delta)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("dialog_advance"):
		timeline.advance(stage)


func _on_input_cover_gui_input(event: InputEvent) -> void:
	if event.is_action_pressed("dialog_advance"):
		timeline.advance(stage)
