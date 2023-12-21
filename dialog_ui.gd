extends Node
class_name DialogUI

@export var dialog_reveal_speed := 90 # in characters per second

@onready var speaker_panel: PanelContainer = %SpeakerPanel
@onready var speaker_label: Label = %SpeakerLabel
@onready var dialog_label: Label = %DialogLabel

var tween: Tween

var is_complete: bool:
	get: return dialog_label.visible_ratio >= 1.0

func set_speaker(name: String) -> void:
	speaker_label.text = name 
	speaker_panel.modulate.a = 1

func set_speaker_self() -> void:
	speaker_panel.modulate.a = 0

func set_line(text: String) -> void:
	dialog_label.text = text

func animate() -> void:
	if tween: tween.stop()

	dialog_label.visible_ratio = 0
	
	tween = create_tween()
	tween.tween_property(
		dialog_label, "visible_ratio", 1,
		float(dialog_label.text.length()) / float(dialog_reveal_speed),
	)

func complete() -> void:
	if tween: tween.stop()
	dialog_label.visible_ratio = 1
