@tool
class_name TextField
extends Control

const NodeHelpers = preload("res://addons/timeline_editor/node_helpers.gd")

signal submitted

@export var label: String:
	set(value):
		label = value
		await NodeHelpers.ensure_ready(self)
		label_node.text = value

@export var placeholder: String:
	set(value):
		placeholder = value
		await NodeHelpers.ensure_ready(self)
		input_node.placeholder_text = value

@export var value: String:
	set(new_value):
		value = new_value
		await NodeHelpers.ensure_ready(self)
		input_node.text = new_value

@export var input_alignment: HorizontalAlignment:
	set(value):
		input_alignment = value
		await NodeHelpers.ensure_ready(self)
		input_node.alignment = value

@onready var label_node: Label = %Label
@onready var input_node: LineEdit = %Input


func _on_input_text_submitted(new_text: String) -> void:
	submitted.emit()
