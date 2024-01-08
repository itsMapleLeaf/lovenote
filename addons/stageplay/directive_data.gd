class_name DirectiveData
extends Resource

@export var dialog := ""

func with_dialog(text: String) -> DirectiveData:
	dialog = text
	return self
