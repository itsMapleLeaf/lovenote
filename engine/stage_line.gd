class_name StageLine

var commands: Array[StageCommand]
var snapshot: StageSnapshot


func _init(commands: Array[StageCommand], base_snapshot: StageSnapshot) -> void:
	self.commands = commands

	snapshot = base_snapshot.copy()
	snapshot.reset_dialog()
	snapshot.apply_commands(commands)


func _to_string() -> String:
	var data := {
		"commands": commands,
		"snapshot": snapshot,
	}
	return "StageLine(%s)" % data
