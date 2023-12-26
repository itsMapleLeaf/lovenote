@tool
class_name Character
extends Control

@export_range(0, 1, 0.05) var stage_position := 0.5:
	set(value):
		stage_position = clampf(value, 0, 1)
		anchor_left = stage_position
		anchor_right = stage_position

@export var sprite_offset := Vector2.ZERO:
	set(value):
		sprite_offset = value
		if not is_node_ready():
			await ready
		sprite.position = value

var tween: Tween

@onready var sprite := %Sprite as Control


func enter_tweened(to_position: float, duration: float) -> void:
	pause_tween()

	tween = create_tween().set_parallel(true)
	tween.tween_property(self, "stage_position", to_position, duration)
	tween.tween_property(self, "modulate", Color(modulate, 1), duration)


func leave_tweened(to_position: float, duration: float) -> void:
	pause_tween()

	tween = create_tween().set_parallel(true)
	tween.tween_property(self, "stage_position", to_position, duration)
	tween.tween_property(self, "modulate", Color(modulate, 0), duration)


func pause_tween() -> void:
	tween.pause()
