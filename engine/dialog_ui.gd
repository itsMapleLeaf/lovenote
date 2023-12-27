@tool
class_name DialogUI
extends Control

## The speed which the text is revealed, in characters per second
@export var dialog_reveal_speed: int

var tween: Tween

@onready var speaker_panel: PanelContainer = %SpeakerPanel
@onready var speaker_label: Label = %SpeakerLabel
@onready var dialog_label: Label = %DialogLabel
@onready var advance_indicator: Control = %AdvanceIndicator


func _ready() -> void:
	clear()


func clear() -> void:
	speaker_label.text = ""
	dialog_label.text = ""
	dialog_label.visible_characters = 0


func set_speaker(speaker: String) -> void:
	speaker_label.text = speaker


func set_text(text: String) -> void:
	dialog_label.text = text


func play_text(text: String) -> void:
	if tween:
		tween.custom_step(INF)

	dialog_label.text += " " + text

	tween = create_tween()
	tween.tween_property(
		dialog_label,
		"visible_characters",
		dialog_label.text.length(),
		float(dialog_label.text.length() - dialog_label.visible_characters) / dialog_reveal_speed
	)


func is_playing() -> bool:
	return tween and tween.is_running()


func set_advance_indicator_visible(invicator_visible: bool) -> void:
	advance_indicator.visible = invicator_visible
