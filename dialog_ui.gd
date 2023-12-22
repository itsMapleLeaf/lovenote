@tool
extends VBoxContainer
class_name DialogUI

## The speed which the text is revealed, in characters per second
@export var dialog_reveal_speed: int

@onready var speaker_panel: PanelContainer = %SpeakerPanel
@onready var speaker_label: Label = %SpeakerLabel
@onready var dialog_label: Label = %DialogLabel

var tween: Tween

func reset() -> void:
	dialog_label.text = ""
	speaker_panel.modulate.a = 0
	if tween: tween.kill()

func set_speaker(name: String) -> void:
	speaker_label.text = name
	speaker_panel.modulate.a = 1

func play_text(text: String) -> void:
	var current_length := dialog_label.text.length()
	var full_length := current_length + text.length()
	var duration := (full_length - current_length) / float(dialog_reveal_speed)

	dialog_label.text += text
	dialog_label.visible_characters = current_length

	if tween: tween.kill()
	tween = create_tween()
	tween.tween_property(dialog_label, "visible_characters", full_length, duration)

func is_playing() -> bool:
	return tween and tween.is_running()

func complete(full_text: String) -> void:
	if tween: tween.kill()
	dialog_label.text = full_text
	dialog_label.visible_characters = -1
