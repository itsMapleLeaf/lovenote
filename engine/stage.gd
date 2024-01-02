class_name Stage
extends Node

signal advanced

@onready var dialog_node: Dialog = %Dialog
@onready var input_cover: Control = %InputCover

var playing: bool = false
var skip_fn: Callable = func() -> void: pass


func timeline() -> void:
	pass


func dialog(directives: Array[Variant]) -> void:
	playing = true
	dialog_node.reset()

	for directive: Variant in directives:
		var dialog_text := directive as String
		if dialog_text:
			var tween := dialog_node.play_text(dialog_text)

			skip_fn = func() -> void:
				dialog_node.skip()
				tween.finished.emit()

			await tween.finished
			continue

		printerr("Unknown directive: " + str(directive))

	playing = false
	await advanced


func _ready() -> void:
	timeline()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("dialog_advance"):
		if playing:
			skip_fn.call()
			playing = false
		else:
			advanced.emit()
