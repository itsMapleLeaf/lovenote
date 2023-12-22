extends Node

const scenes: Array[PackedScene] = [
	preload("res://scenes/ryder.tscn"),
]

var scene_index := 0

@onready var scene_container: Node = %SceneContainer

func _ready() -> void:
	_load_scene(0)

func _load_scene(index: int) -> void:
	for child in scene_container.get_children(): child.queue_free()
	scene_container.add_child(scenes[index].instantiate())
