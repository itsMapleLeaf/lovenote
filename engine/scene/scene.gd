class_name Scene
extends Control

@onready var background := %Background as TextureRect


func transition_to_background(texture: Texture2D) -> void:
	var old_background := background
	background = background.duplicate() as TextureRect

	background.texture = texture

	background.modulate.a = 0
	var tween := get_tree().create_tween()
	tween.tween_property(background, "modulate", Color(background.modulate, 1), 1)

	add_child(background)

	await tween.finished

	old_background.queue_free()
