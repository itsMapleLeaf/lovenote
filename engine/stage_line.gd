class_name StageLine

var commands: Array[StageCommand]
var snapshot: StageState


func _init(commands: Array[StageCommand], base_snapshot: StageState) -> void:
	self.commands = commands

	snapshot = base_snapshot.duplicate(true) as StageState
	snapshot.speaker = ""

	var new_text := PackedStringArray()

	for command in commands:
		match command.name:
			"dialog":
				new_text.append(command.value)
			"speaker":
				snapshot.speaker = command.value
			"background":
				snapshot.background = command.value
			"enter":
				var name := command.get_required_arg(0)
				var position := command.get_required_arg("to").to_float()
				snapshot.characters.append(StageState.CharacterState.new(name, position))
			"leave":
				for index in snapshot.characters.size():
					var character := snapshot.characters[index]
					if character.name == command.args[0]:
						snapshot.characters.remove_at(index)
						break

	snapshot.text = " ".join(new_text)


func _to_string() -> String:
	var data := {
		"commands": commands,
		"snapshot": snapshot,
	}
	return "StageLine(%s)" % data
