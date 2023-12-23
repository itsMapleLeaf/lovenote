extends Node

const scenes: Array[PackedScene] = [
	preload("res://scenes/ryder/the_first_day.tscn"),
	# preload("res://scenes/ryder/new_friends.tscn"),
	# preload("res://scenes/ryder/the_first_meeting.tscn"),
	# preload("res://scenes/ryder/not_a_crush.tscn"),
	# preload("res://scenes/ryder/friction.tscn"),
	# preload("res://scenes/ryder/understanding.tscn"),
]

var scene_index := 0

@onready var scene_container: Node = %SceneContainer

func _ready() -> void:
	_load_scene(0)

func _load_scene(index: int) -> void:
	for child in scene_container.get_children(): child.queue_free()
	scene_container.add_child(scenes[index].instantiate())
