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

var visible_characters: int:
	get:
		return dialog_label.visible_characters
	set(value):
		dialog_label.visible_characters = value

var advance_indicator_visible: bool:
	get:
		return advance_indicator.visible
	set(value):
		advance_indicator.visible = value
