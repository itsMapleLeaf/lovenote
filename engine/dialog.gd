class_name Dialog
extends Control

@export var speaker := ""
@export var text := ""
@export var advance_indicator_visible := false

## Speed that characters are revealed in characters per second
@export var reveal_speed: int

var visible_characters := 0.0
var extra_spaces := RegEx.create_from_string(r"\s{2,}")

@onready var speaker_panel: PanelContainer = %SpeakerPanel
@onready var speaker_label: Label = %SpeakerLabel
@onready var dialog_label: RichTextLabel = %DialogLabel
@onready var advance_indicator: Control = %AdvanceIndicator


func reset() -> void:
	speaker = ""
	text = ""
	visible_characters = 0


func skip() -> void:
	visible_characters = text.length()


func is_playing() -> bool:
	return visible_characters < text.length()


func _process(delta: float) -> void:
	if speaker == "":
		speaker_panel.visible = false
	else:
		speaker_panel.visible = true
		speaker_label.text = speaker

	if text == "":
		visible = false
	else:
		visible = true
		dialog_label.text = extra_spaces.sub(text.strip_edges(), " ", true)

	if visible_characters < text.length():
		visible_characters = move_toward(visible_characters, text.length(), reveal_speed * delta)
	else:
		visible_characters = text.length()
	dialog_label.visible_characters = ceili(visible_characters)

	advance_indicator.visible = advance_indicator_visible
