extends Node

@onready var timeline_player := %TimelinePlayer as TimelinePlayer


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("dialog_advance"):
		timeline_player.advance()
	elif event.is_action_pressed("dialog_prev"):
		timeline_player.position -= 1
	elif event.is_action_pressed("dialog_next"):
		timeline_player.position += 1
