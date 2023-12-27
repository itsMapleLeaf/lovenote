class_name AbortController

signal aborted

var _is_aborted := false

var is_aborted: bool:
	get:
		return _is_aborted

func abort() -> void:
	if _is_aborted:
		return
	aborted.emit()
	_is_aborted = true

func wait_for(duration_seconds: float) -> void:
	var end_time := Time.get_ticks_msec() + duration_seconds * 1000
	var scene_tree := Engine.get_main_loop() as SceneTree
	while Time.get_ticks_msec() < end_time and not is_aborted:
		await scene_tree.process_frame
