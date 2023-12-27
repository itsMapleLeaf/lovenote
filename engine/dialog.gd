class_name Dialog
extends Control

## Speed that characters are revealed in characters per second
@export var reveal_speed: int

var extra_spaces := RegEx.create_from_string(r"\s{2,}")

@onready var speaker_panel: PanelContainer = %SpeakerPanel
@onready var speaker_label: Label = %SpeakerLabel
@onready var dialog_label: Label = %DialogLabel
@onready var advance_indicator: Control = %AdvanceIndicator

func clear() -> void:
	visible = false
	speaker_label.text = ""
	dialog_label.text = ""

func set_speaker(speaker_name: String) -> void:
	if speaker_name == "":
		speaker_label.visible = false
	else:
		speaker_label.visible = true
		speaker_label.text = speaker_name

func play_text(text: String, skip_controller: AbortController) -> void:
	var visible_characters := float(dialog_label.text.length())
	var target_visible_characters := visible_characters + text.length()

	dialog_label.text = extra_spaces.sub((dialog_label.text + " " + text).strip_edges(), " ", true)
	visible = true

	while visible_characters < target_visible_characters and not skip_controller.is_aborted:
		visible_characters += reveal_speed * get_process_delta_time()
		dialog_label.visible_characters = ceili(visible_characters)

		await get_tree().process_frame

	dialog_label.visible_ratio = 1
