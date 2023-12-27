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

var character_name: String = ""
var tween: Tween

@onready var sprite := %Sprite as Control

func _ready() -> void:
	modulate.a = 0

func enter_tweened(from_position: float, to_position: float, duration: float) -> void:
	pause_tween()

	stage_position = to_position + from_position # from_position is relative
	tween = create_tween().set_parallel(true).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(self, "stage_position", to_position, duration)
	tween.tween_property(self, "modulate", Color(modulate, 1), duration)


func leave_tweened(by_position: float, duration: float) -> void:
	pause_tween()

	tween = create_tween().set_parallel(true).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(self, "stage_position", stage_position + by_position, duration)
	tween.tween_property(self, "modulate", Color(modulate, 0), duration)

	await tween.finished

	queue_free()


func pause_tween() -> void:
	if tween: tween.pause()
