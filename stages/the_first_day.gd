extends Stage

var dialog_reveal_speed: int = 10
var dialog_reveal_speed_scale: float = 1.0

@onready var office_far: Control = %OfficeFar
@onready var ryder: Control = %Ryder
@onready var dialog: Dialog = %Dialog


func timeline() -> void:
	var office_far_opacity := prop(0.0, func(value: float) -> void: office_far.modulate.a = value)
	var ryder_opacity := prop(0.0, func(value: float) -> void: ryder.modulate.a = value)

	var dialog_text := prop("", func(value: String) -> void: dialog.text = value)
	var dialog_visible_characters := prop(
		0, func(value: int) -> void: dialog.visible_characters = value
	)

	line(
		[
			office_far_opacity.set_to(0),
			ryder_opacity.set_to(0),
			dialog_text.set_to("Well, here I am."),
			(
				dialog_visible_characters
				. tween_to(
					func(value: int) -> int: return value + "Well, here I am.".length(),
					"Well, here I am.".length() / (dialog_reveal_speed * dialog_reveal_speed_scale),
				)
			),
		]
	)
	# line([dialog_text.set_to("This is it.")])
	# line(
	# 	[
	# 		"I'm not really nervous. When it comes to stuff like this, as long as there's a set time and place, I just go and deal with it.",
	# 	]
	# )
	# line(["..."])
	# line(["I'm a liar. I'm really nervous."])
	# # line(["I want to disintegrate into dust."])
	# line(["But my one true talent is hiding that. So I'll be fine."])
	# # line(["Probably."])
	# line(
	# 	[
	# 		office_far_opacity.tween_to(1.0, 1.0),
	# 		"It's kind of a cozy-looking place, surprisingly. Not nearly as tall as those high rise office skyscrapers.",
	# 	]
	# )
