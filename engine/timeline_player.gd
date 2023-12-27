class_name TimelinePlayer
extends Node

@export_multiline var timeline_source := ""
@export var current_line_index := 0

var skip_controller := AbortController.new()
var playing := false

@onready var timeline := Timeline.new(timeline_source)
@onready var stage: Stage = %Stage


func _ready() -> void:
	_advance()


func _play_line(line: Timeline.StageLine) -> void:
	playing = true
	skip_controller = AbortController.new()
	stage.dialog.clear()
	stage.dialog.advance_indicator.visible = false

	for directive in line.directives:
		if skip_controller.is_aborted:
			break

		var speaker_directive := directive as Timeline.SpeakerDirective
		if speaker_directive:
			stage.dialog.set_speaker(speaker_directive.speaker_name)
			continue

		var dialog_directive := directive as Timeline.DialogDirective
		if dialog_directive:
			await stage.dialog.play_text(dialog_directive.dialog_text, skip_controller)
			continue

		var background_directive := directive as Timeline.BackgroundDirective
		if background_directive:
			stage.set_background(background_directive.background)
			continue

		var wait_directive := directive as Timeline.WaitDirective
		if wait_directive:
			await skip_controller.wait_for(wait_directive.duration)
			continue

		var enter_directive := directive as Timeline.EnterDirective
		if enter_directive:
			stage.enter_character(
				enter_directive.character_name,
				enter_directive.from_position,
				enter_directive.to_position,
				enter_directive.duration
			)
			continue

		var leave_directive := directive as Timeline.LeaveDirective
		if leave_directive:
			stage.leave_character(
				leave_directive.character_name,
				leave_directive.by_position,
				leave_directive.duration
			)
			continue

	playing = false
	stage.dialog.advance_indicator.visible = true


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("dialog_advance"):
		if playing:
			skip_controller.abort()
		else:
			_advance()


func _advance() -> void:
	if current_line_index < timeline.lines.size():
		_play_line(timeline.lines[current_line_index])
		current_line_index += 1


func _skip() -> void:
	pass # todo
