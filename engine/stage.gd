class_name Stage
extends Node

@export var background_fade_duration := 1.0

var background: Background

@onready var background_layer: Node = %BackgroundLayer
@onready var character_layer: Node = %CharacterLayer
@onready var dialog: Dialog = %Dialog

func set_background(texture: Texture2D) -> void:
	if background:
		background.leave(background_fade_duration)

	background = preload("res://engine/background.tscn").instantiate()
	background_layer.add_child(background)
	background.enter(texture, background_fade_duration)

func enter_character(character_name: String, from_position: float, to_position: float, duration: float) -> void:
	var scene := load("res://content/characters/" + character_name + ".tscn") as PackedScene
	var character := scene.instantiate() as Character
	if not character:
		push_error("Character %s is not a Character" % character_name)
		return

	character_layer.add_child(character)
	character.character_name = character_name
	character.enter_tweened(from_position, to_position, duration)

func leave_character(character_name: String, by_position: float, duration: float) -> void:
	var character: Character
	for child in character_layer.get_children():
		if child.name == character_name:
			character = child
			break

	if not character:
		return

	character.leave_tweened(by_position, duration)
