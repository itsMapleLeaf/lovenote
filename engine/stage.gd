@tool
class_name Stage
extends Node

@onready var background := %Background as TextureRect
@onready var characters := %Characters as Node
@onready var dialog_ui := %DialogUI as DialogUI


func run_command(command: StageCommand) -> void:
	if command is StageCommand.SpeakerCommand:
		dialog_ui.speaker = command.speaker

	if command is StageCommand.DialogCommand:
		dialog_ui.play_text(command.text)

	if command is StageCommand.BackgroundCommand:
		if command.background.is_empty():
			background.modulate.a = 0
		else:
			background.texture = load("res://content/backgrounds/" + command.background)
			background.modulate.a = 1

	if command is StageCommand.EnterCommand:
		var scene_path: String = "res://content/characters/%s.tscn" % command.character_name
		var scene := load(scene_path) as PackedScene
		var character := scene.instantiate() as Character
		characters.add_child(character)
		character.character_name = command.character_name
		character.stage_position = command.from_position
		character.enter_tweened(command.to_position, command.duration)

	if command is StageCommand.LeaveCommand:
		for character: Character in characters.get_children():
			if character.character_name == command.character_name:
				character.leave_tweened(command.by_position, command.duration)


func is_running_command() -> bool:
	return dialog_ui.is_playing()


func apply(snapshot: StageSnapshot) -> void:
	if snapshot.background.is_empty():
		background.modulate.a = 0
	else:
		background.texture = load("res://content/backgrounds/" + snapshot.background)
		background.modulate.a = 1

	dialog_ui.set_speaker(snapshot.speaker)
	dialog_ui.set_text(snapshot.text)

	for character in characters.get_children():
		character.queue_free()

	for character_state in snapshot.characters:
		var scene_path := "res://content/characters/%s.tscn" % character_state.name
		var scene := load(scene_path) as PackedScene
		var character := scene.instantiate() as Character
		character.stage_position = character_state.stage_position
		characters.add_child(character)
