@icon("res://assets/Play.png")
class_name DialoguePlayer
extends Node

signal text_changed(text: String)
signal visible_character_count_changed(count: int)

@export var reveal_speed: int = 50
@export var lines: Array[DialogueLine] = []

var line_index := 0
var visible_characters := 0.0

var current_line: DialogueLine:
	get:
		if lines.size() > 0:
			return lines[clampi(line_index, 0, lines.size() - 1)]
		else:
			return DialogueLine.new()

var current_line_length: int:
	get:
		return current_line.text.length()

@onready var min_wait_timer: Timer = %MinWaitTimer


func _process(delta: float) -> void:
	visible_characters = minf(
		visible_characters + reveal_speed * delta,
		current_line_length,
	)
	visible_character_count_changed.emit(ceili(visible_characters))


func play(index: int) -> void:
	line_index = clampi(index, 0, lines.size() - 1)
	visible_characters = 0
	min_wait_timer.start()
	await get_tree().process_frame
	text_changed.emit(current_line.text)


func play_next() -> void:
	play(line_index + 1)


func play_previous() -> void:
	play(line_index - 1)


func is_playing() -> bool:
	return (
		visible_characters < current_line_length
		or !min_wait_timer.is_stopped()
	)


func skip() -> void:
	visible_characters = current_line_length
	min_wait_timer.stop()
