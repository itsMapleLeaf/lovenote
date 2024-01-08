@tool
class_name TextField
extends PanelContainer

@export var label: String:
	set(value):
		label = value
		await _ensure_ready()
		label_node.text = value

@export var placeholder: String:
	set(value):
		placeholder = value
		await _ensure_ready()
		input_node.placeholder_text = value

@export var value: String:
	set(new_value):
		value = new_value
		await _ensure_ready()
		input_node.text = new_value

@export var input_alignment: HorizontalAlignment:
	set(value):
		input_alignment = value
		await _ensure_ready()
		input_node.alignment = value

@onready var label_node: Label = %Label
@onready var input_node: LineEdit = %Input

func _ensure_ready() -> void:
	if not is_node_ready(): await ready
