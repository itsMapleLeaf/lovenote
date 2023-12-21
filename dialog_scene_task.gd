extends SceneTask
class_name DialogSceneTask

var line: String
var ui: DialogUI
var speaker_name: String

func _init(line: String, ui: DialogUI) -> void:
	self.line = line
	self.ui = ui

func start() -> void:
	if speaker_name:
		ui.set_speaker(speaker_name)
	else:
		ui.set_speaker_self()
	ui.set_line(line)
	ui.animate()
	
func interrupt() -> void:
	ui.complete()

func is_finished() -> bool:
	return ui.is_complete
