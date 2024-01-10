@tool

static func get_template_data() -> TimelineData:
	return TimelineData.new([
		LineData.new("Ryder", [
			DirectiveData.new().with_dialog("I wonder what it's like to die."),
		]),
		LineData.new("Reina", [
			DirectiveData.new().with_dialog("..."),
			DirectiveData.new().with_dialog("Ryder, what?"),
		]),
		LineData.new("Ryder", [
			DirectiveData.new().with_dialog("I'm just curious."),
		]),
	])
