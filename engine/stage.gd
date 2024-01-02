class_name Stage
extends Node

signal advanced

var timeline_items: Array[TimelineItem] = []
var timeline_item_index : = 0
var is_playing := false
var skip_fn := func() -> void: pass

@onready var dialog_node: Dialog = %Dialog
@onready var input_cover: Control = %InputCover


func timeline() -> void:
	pass


func dialog(directives: Array) -> void:
	timeline_items.append(TimelineItem.new(directives))


func _ready() -> void:
	timeline()
	_play_timeline_item(0)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("dialog_advance"):
		if is_playing:
			_skip()
		else:
			_play_timeline_item(timeline_item_index + 1)

	if event.is_action_pressed("dialog_back"):
		_skip()
		_play_timeline_item(timeline_item_index - 1)
		_skip()

	if event.is_action_pressed("dialog_next"):
		_skip()
		_play_timeline_item(timeline_item_index + 1)
		_skip()


func _play_timeline_item(index: int) -> void:
	if timeline_items.size() == 0:
		return

	timeline_item_index = clampi(index, 0, timeline_items.size() - 1)

	is_playing = true
	dialog_node.reset()

	for directive: Variant in timeline_items[timeline_item_index].directives:
		if not is_playing:
			break

		if directive is String:
			var dialog_text := directive as String
			if dialog_text:
				var tween := dialog_node.play_text(dialog_text)

				skip_fn = func() -> void:
					dialog_node.skip()
					tween.finished.emit()

				await tween.finished
				continue

			printerr("Unexpected directive: " + str(directive))

	is_playing = false


func _skip() -> void:
	is_playing = false
	skip_fn.call()
	dialog_node.text = timeline_items[timeline_item_index].dialog_text


class TimelineItem:
	var directives: Array = []
	var dialog_text := ""

	func _init(directives: Array) -> void:
		self.directives = directives

		for directive: Variant in directives:
			if directive is String:
				dialog_text += " " + directive
