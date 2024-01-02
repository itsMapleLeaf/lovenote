extends Stage

@onready var office_far: Control = %OfficeFar

@onready var ryder: Control = %Ryder


func timeline() -> void:
	await dialog(["Well, here I am."])
	await dialog(["This is it."])
	await dialog(
		[
			"I'm not really nervous. When it comes to stuff like this, as long as there's a set time and place, I just go and deal with it."
		]
	)
	await dialog(["..."])
	await dialog(["I'm a liar. I'm really nervous."])
	await dialog(["I want to disintegrate into dust."])
	await dialog(["But my one true talent is hiding that. So I'll be fine."])
	await dialog(["Probably."])
