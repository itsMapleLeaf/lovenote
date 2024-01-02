extends Stage

@onready var office_far: Control = %OfficeFar

@onready var ryder: Control = %Ryder


func timeline() -> void:
	dialog(["Well, here I am."])
	dialog(["This is it."])
	dialog(
		[
			"I'm not really nervous. When it comes to stuff like this, as long as there's a set time and place, I just go and deal with it."
		]
	)
	dialog(["..."])
	dialog(["I'm a liar. I'm really nervous."])
	dialog(["I want to disintegrate into dust."])
	dialog(["But my one true talent is hiding that. So I'll be fine."])
	dialog(["Probably."])
