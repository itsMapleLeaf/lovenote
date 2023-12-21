extends SceneTask
class_name AnimationPlayerTask
	
var player: AnimationPlayer
var animation_name: StringName

func _init(player: AnimationPlayer, animation_name: StringName) -> void:
	self.player = player
	self.animation_name = animation_name

func start() -> void:
	player.play(animation_name)
	advance.emit()
	await player.animation_finished
	queue_free()
