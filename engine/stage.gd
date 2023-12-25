@tool
class_name Stage
extends Node

@onready var background := %Background as TextureRect
@onready var characters := %Characters as Node
@onready var dialog_ui := %DialogUI as DialogUI


func apply_snapshot(snapshot: StageState) -> void:
	if snapshot.background.is_empty():
		background.modulate.a = 0
	else:
		background.texture = load("res://content/backgrounds/" + snapshot.background)
		background.modulate.a = 1

	dialog_ui.speaker = snapshot.speaker
	dialog_ui.text = snapshot.text

	for character in characters.get_children():
		character.queue_free()

	for character_state in snapshot.characters:
		var scene_path := "res://content/characters/%s.tscn" % character_state.name
		var scene := load(scene_path) as PackedScene
		var character := scene.instantiate() as Character
		character.stage_position = character_state.stage_position
		characters.add_child(character)
