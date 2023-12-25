@tool
class_name DialogUI
extends Control

## The speed which the text is revealed, in characters per second
@export var dialog_reveal_speed: int

@export var text: String = "":
	set(value):
		text = value
		await _await_ready()
		dialog_label.text = value
		modulate.a = 1 if not value.is_empty() else 0
	get:
		return dialog_label.text

@export var speaker: String = "":
	set(value):
		speaker = value
		await _await_ready()
		speaker_label.text = value
		speaker_panel.visible = value != ""
	get:
		return speaker_label.text

@export var advance_indicator_visible: bool = false:
	set(value):
		advance_indicator_visible = value
		await _await_ready()
		advance_indicator.visible = value
	get:
		return advance_indicator.visible

var tween: Tween

@onready var speaker_panel: PanelContainer = %SpeakerPanel
@onready var speaker_label: Label = %SpeakerLabel
@onready var dialog_label: Label = %DialogLabel
@onready var advance_indicator: Control = %AdvanceIndicator


func clear() -> void:
	text = ""
	speaker = ""
	advance_indicator_visible = false


func _await_ready() -> void:
	if not is_node_ready():
		await ready
