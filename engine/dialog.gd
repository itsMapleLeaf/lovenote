class_name Dialog
extends Control

@export var speaker := ""
@export_multiline var text := ""
@export var reveal_speed := 0
@export var advance_indicator_visible := true

var extra_spaces := RegEx.create_from_string(r"\s{2,}")

# keep the visible characters as a float so we can smoothly animate it
var visible_characters := 0.0

@onready var speaker_panel: PanelContainer = %SpeakerPanel
@onready var speaker_label: Label = %SpeakerLabel
@onready var dialog_label: Label = %DialogLabel
@onready var advance_indicator: Control = %AdvanceIndicator


func _get_configuration_warnings() -> PackedStringArray:
	var warnings := []

	if reveal_speed < 0:
		warnings.append("Reveal speed should be greater than 0")

	return warnings


func _process(delta: float) -> void:
	if visible_characters < text.length():
		visible_characters = move_toward(visible_characters, text.length(), delta * reveal_speed)
	else:
		visible_characters = text.length()

	if not is_node_ready():
		return

	if speaker == "":
		speaker_panel.visible = false
	else:
		speaker_panel.visible = true
		speaker_label.text = speaker

	if text == "":
		dialog_label.visible = false
	else:
		dialog_label.visible = true
		dialog_label.text = extra_spaces.sub(text.strip_edges(), " ", true)
		dialog_label.visible_characters = ceili(visible_characters)
