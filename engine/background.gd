extends Control

var tween: Tween


func fade_in(duration := 1.0) -> void:
	if tween:
		tween.kill()
	tween = create_tween()
	tween.tween_property(self, "modulate:a", 1, duration)
	await tween.finished


func fade_out(duration := 1.0) -> void:
	if tween:
		tween.kill()
	tween = create_tween()
	tween.tween_property(self, "modulate:a", 0, duration)
	await tween.finished
