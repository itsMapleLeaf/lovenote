class_name DialogueLine
extends Resource

@export_multiline var text := ""

func _init(text := "") -> void:
	self.text = text
