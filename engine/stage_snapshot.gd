class_name StageSnapshot
extends Resource

@export var background: String = ""
@export var speaker: String = ""
@export var characters: Array[CharacterSnapshot] = []

@export var text: String = "":
	set(input):
		text = extra_white_space.sub(input.strip_edges(), " ", true)

var extra_white_space := RegEx.create_from_string(r"\s+")


func _to_string() -> String:
	var data := {
		"speaker": speaker,
		"text": text,
		"background": background,
		"characters": characters,
	}
	return "StageSnapshot(%s)" % data


class CharacterSnapshot:
	extends Resource

	@export var name: String = ""
	@export var stage_position: float = 0

	func _init(name := "", stage_position := 0.0) -> void:
		self.name = name
		self.stage_position = stage_position

	func _to_string() -> String:
		var data := {
			"name": name,
			"stage_position": stage_position,
		}
		return "CharacterSnapshot(%s)" % data
