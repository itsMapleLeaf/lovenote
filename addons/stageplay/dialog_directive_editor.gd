@tool
class_name DialogDirectiveEditor
extends TextEdit

static func create(text := "") -> DialogDirectiveEditor:
	var instance: DialogDirectiveEditor = preload("res://addons/stageplay/dialog_directive_editor.tscn").instantiate()
	instance.text = text
	return instance


func pack() -> DirectiveData:
	var data := DirectiveData.new()
	data.dialog = text
	return data
