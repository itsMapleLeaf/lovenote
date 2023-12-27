class_name StageSnapshot

var background: String = ""
var speaker: String = ""
var characters: Array[CharacterSnapshot] = []

var text: String = "":
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


func copy() -> StageSnapshot:
	var snapshot := StageSnapshot.new()
	snapshot.background = background
	snapshot.speaker = speaker
	snapshot.text = text
	snapshot.characters = []

	for character in characters:
		snapshot.characters.append(character.copy())

	return snapshot


func reset_dialog() -> void:
	speaker = ""
	text = ""


func apply_directives(directives: Array[StageDirective]) -> void:
	for directive in directives:
		if directive is StageDirective.DialogDirective:
			text += " " + directive.text
		elif directive is StageDirective.SpeakerDirective:
			speaker = directive.speaker
		elif directive is StageDirective.BackgroundDirective:
			background = directive.background_name
		elif directive is StageDirective.EnterDirective:
			characters.append(
				CharacterSnapshot.new(directive.character_name, directive.to_position)
			)
		elif directive is StageDirective.LeaveDirective:
			for index in characters.size():
				var character := characters[index]
				if character.name == directive.character_name:
					characters.remove_at(index)
					break


class CharacterSnapshot:
	var name: String = ""
	var stage_position: float = 0

	func _init(name := "", stage_position := 0.0) -> void:
		self.name = name
		self.stage_position = stage_position

	func _to_string() -> String:
		var data := {
			"name": name,
			"stage_position": stage_position,
		}
		return "CharacterSnapshot(%s)" % data

	func copy() -> CharacterSnapshot:
		return CharacterSnapshot.new(name, stage_position)
