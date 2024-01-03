class_name Stage
extends Node

signal advanced
signal skipped

var stage_lines: Array[StageLine] = []
var stage_line_index := 0
var stage_props := {}
var is_playing := false
var skip_fn := func() -> void: pass

@onready var input_cover: Control = %InputCover


func timeline() -> void:
	pass


func prop(initial_value: Variant, callback: Callable) -> StageProp:
	var prop := StageProp.new(initial_value, callback)
	callback.call(initial_value)
	stage_props[prop.key] = prop
	return prop


func line(directive_inputs: Array) -> void:
	var line := StageLine.new()

	for input: Variant in directive_inputs:
		if input is StageDirective:
			line.directives.append(input as StageDirective)
			continue

		printerr("Invalid line input: " + str(input))

	stage_lines.append(line)


# func dialog() -> void:
# 	var dialog_text := prop("", func(value: String) -> void: dialog.text = value)
# 	var dialog_visible_characters := prop(
# 		0, func(value: int) -> void: dialog.visible_characters = value
# 	)


func _ready() -> void:
	timeline()
	_create_snapshots()
	_play_timeline_item(0)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("dialog_advance"):
		if is_playing:
			_play_timeline_item_skipped(stage_line_index)
		else:
			_play_timeline_item(stage_line_index + 1)

	if event.is_action_pressed("dialog_back"):
		_play_timeline_item_skipped(stage_line_index - 1)

	if event.is_action_pressed("dialog_next"):
		_play_timeline_item_skipped(stage_line_index + 1)


func _create_snapshots() -> void:
	var current_prop_values := {}

	for line in stage_lines:
		line.start_prop_values = current_prop_values

		for directive in line.directives:
			var update_prop_directive := directive as UpdatePropDirective
			if update_prop_directive:
				var prop := update_prop_directive.prop
				var value: Variant = update_prop_directive.new_value

				if current_prop_values.has(prop.key) and current_prop_values[prop.key] != value:
					current_prop_values = current_prop_values.duplicate()
					current_prop_values[prop.key] = value

		line.end_prop_values = current_prop_values


func _play_timeline_item(index: int) -> void:
	if stage_lines.size() == 0:
		return

	stage_line_index = clampi(index, 0, stage_lines.size() - 1)
	var line := stage_lines[stage_line_index]

	skip_fn.call()
	_apply_prop_values(line.start_prop_values)
	is_playing = true

	for directive in line.directives:
		if not is_playing:
			break

		await directive.play(self)

	is_playing = false


func _play_timeline_item_skipped(index: int) -> void:
	if stage_lines.size() == 0:
		return

	is_playing = false
	skip_fn.call()

	stage_line_index = clampi(index, 0, stage_lines.size() - 1)
	var item := stage_lines[stage_line_index]

	_apply_prop_values(item.end_prop_values)


func _apply_prop_values(prop_values: Dictionary) -> void:
	for key: int in prop_values:
		var prop: StageProp = stage_props[key]
		var value: Variant = prop_values[key]
		prop.current_value = value


class StageProp:
	static var next_key := 0

	var key: int
	var initial_value: Variant
	var callback: Callable

	var current_value: Variant:
		get:
			return current_value
		set(value):
			current_value = value
			callback.call_deferred(value)

	func _init(initial_value: Variant, callback: Callable) -> void:
		self.initial_value = initial_value
		self.current_value = initial_value
		self.callback = callback

		key = next_key
		next_key += 1

	func tween_to(update: Variant, tween_duration: float) -> UpdatePropDirective:
		return UpdatePropDirective.new(self, update, tween_duration)

	func set_to(update: Variant) -> UpdatePropDirective:
		return tween_to(update, 0)


class StageLine:
	var directives: Array[StageDirective] = []
	var start_prop_values := {}
	var end_prop_values := {}


class StageDirective:
	func play(_stage: Stage) -> void:
		pass


class UpdatePropDirective:
	extends StageDirective

	var prop: StageProp
	var new_value: Variant
	var tween_duration: float
	var is_blocking := false

	func _init(prop: StageProp, new_value: Variant, tween_duration: float) -> void:
		self.prop = prop
		self.new_value = new_value
		self.tween_duration = tween_duration

	func blocking() -> UpdatePropDirective:
		is_blocking = true
		return self

	func play(stage: Stage) -> void:
		var target_value: Variant = (
			(new_value as Callable).call(prop.current_value) if new_value is Callable else new_value
		)

		var tween := stage.create_tween()
		tween.tween_property(prop, "current_value", target_value, tween_duration)

		var _on_skip := func() -> void:
			tween.finished.emit()
			tween.kill()

		stage.skipped.connect(_on_skip, CONNECT_ONE_SHOT)

		if is_blocking:
			await tween.finished
