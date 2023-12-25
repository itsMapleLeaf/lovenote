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


static func reset_dialog(snapshot: StageSnapshot) -> void:
	snapshot.speaker = ""
	snapshot.text = ""


static func apply_commands(snapshot: StageSnapshot, commands: Array[StageCommand]) -> void:
	var characters := snapshot.characters.duplicate() as Array[CharacterSnapshot]

	for command in commands:
		match command.name:
			"dialog":
				snapshot.text += " " + command.value
			"speaker":
				snapshot.speaker = command.value
			"background":
				snapshot.background = command.value
			"enter":
				var name := command.get_required_arg(0)
				var position := command.get_required_arg("to").to_float()
				characters.append(StageSnapshot.CharacterSnapshot.new(name, position))
			"leave":
				for index in characters.size():
					var character := characters[index]
					if character.name == command.args[0]:
						characters.remove_at(index)
						break

	snapshot.characters = characters


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
