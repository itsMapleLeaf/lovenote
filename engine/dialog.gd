class_name Dialog
extends Control

@onready var speaker_panel: Control = %SpeakerPanel
@onready var speaker_label: Label = %SpeakerLabel
@onready var dialog_label: RichTextLabel = %DialogLabel
@onready var advance_indicator: Control = %AdvanceIndicator

var extra_spaces := RegEx.create_from_string(r"s{2,}")

var speaker: String:
	get:
		return speaker_label.text
	set(value):
		speaker_label.text = value
		speaker_panel.visible = value != ""

var text: String:
	get:
		return dialog_label.text
	set(value):
		dialog_label.text = extra_spaces.sub(value, " ", true).strip_edges()
		visible = value != ""

var advance_indicator_visible: bool:
	get:
		return advance_indicator.visible
	set(value):
		advance_indicator.visible = value

var reveal_speed: int = 50
var reveal_speed_scale: float = 1.0

var _tween: Tween


func reset() -> void:
	speaker = ""
	text = ""
	reveal_speed_scale = 1.0


func play_text(new_text: String) -> Tween:
	var current_length := text.length()
	text += " " + new_text
	var target_length := text.length()

	dialog_label.visible_characters = current_length

	_tween = create_tween()
	_tween.tween_property(
		dialog_label,
		"visible_characters",
		target_length,
		(target_length - current_length) / (reveal_speed * reveal_speed_scale)
	)

	return _tween


func skip() -> void:
	_tween.kill()
	dialog_label.visible_ratio = 1.0
