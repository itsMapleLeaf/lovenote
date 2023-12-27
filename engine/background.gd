class_name Background
extends TextureRect

func _ready() -> void:
	modulate.a = 0

func enter(new_texture: Texture2D, fade_duration: float) -> void:
	texture = new_texture

	var tween := create_tween()
	tween.tween_property(self, "modulate", Color(modulate, 1), fade_duration).from(Color(modulate, 0))

func leave(fade_duration: float) -> void:
	var tween := create_tween()
	tween.tween_property(self, "modulate", Color(modulate, 0), fade_duration).from(Color(modulate, 1))
	await tween.finished
	queue_free()
