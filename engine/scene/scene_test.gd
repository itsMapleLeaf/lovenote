extends Control

@onready var scene := %Scene as Scene


func _on_office_wide_view_button_pressed() -> void:
	scene.transition_to_background(preload("res://backgrounds/office_outdoors.png"))


func _on_office_interior_button_pressed() -> void:
	scene.transition_to_background(preload("res://backgrounds/office_interior.png"))


func _on_office_front_door_button_pressed() -> void:
	scene.transition_to_background(preload("res://backgrounds/office_front_door.tres"))
