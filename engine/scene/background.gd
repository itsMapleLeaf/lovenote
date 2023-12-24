@tool
class_name Background
extends Control

var tween: Tween

@onready var back := %Back as TextureRect
@onready var front := %Front as TextureRect


func transition_to_background(texture: Texture2D) -> void:
	if tween:
		tween.custom_step(INF)

	back.texture = texture
	back.modulate.a = 0

	tween = get_tree().create_tween()
	tween.tween_property(back, "modulate", Color(back.modulate, 1), 1).set_ease(Tween.EASE_OUT)

	move_child(front, 0)

	var back_tmp := back
	back = front
	front = back_tmp
