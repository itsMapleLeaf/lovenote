extends Node
class_name Helpers

static func seek_animation(player: AnimationPlayer, name: StringName, time: float) -> void:
	player.current_animation = name
	player.play()
	player.seek(time, true, true)
	player.pause()
