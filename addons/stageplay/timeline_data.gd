class_name TimelineData
extends Resource

@export var lines: Array[LineData] = []

func _init(lines: Array[LineData]) -> void:
	self.lines = lines
