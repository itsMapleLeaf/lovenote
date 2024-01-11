extends Control

@export var player: DialoguePlayer


func _ready() -> void:
	player.play(0)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("dialog_advance"):
		if player.is_playing():
			player.skip()
		else:
			player.play_next()

	if event.is_action_pressed("dialog_next"):
		player.play_next()
		player.skip()

	if event.is_action_pressed("dialog_back"):
		player.play_previous()
		player.skip()


func _gui_input(event: InputEvent) -> void:
	_unhandled_input(event)
