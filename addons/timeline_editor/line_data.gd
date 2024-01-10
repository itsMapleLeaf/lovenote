class_name LineData
extends Resource

@export var speaker: String = ""
@export var directives: Array[DirectiveData] = []

func _init(speaker: String, directives: Array[DirectiveData]) -> void:
	self.speaker = speaker
	self.directives = directives
