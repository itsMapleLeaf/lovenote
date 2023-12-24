class_name DialogLine

var parts: Array[DialogLinePart] = []
var speaker: String

# matches any arbitrary text, followed by an optional directive,
# which has the syntax [directive_name:directive_value]
# example: "I decide to make my entrance. [character_enter:player] Hi there!"
var text_and_directive_regex := RegEx.create_from_string(
	r"(?<text>[^\[]+)?(?:\[(?:(?<directive_name>[a-z_]+):?)?(?<directive_value>.+?)\]\s*)?"
)


func _init(source_line: String) -> void:
	for match in text_and_directive_regex.search_all(source_line):
		var text := match.get_string("text")
		var directive_name := match.get_string("directive_name")
		var directive_value := match.get_string("directive_value")

		if text and not text.is_empty():
			parts.append(TextPart.new(text))

		if directive_name and directive_value:
			parts.append(DirectivePart.new(directive_name, directive_value))
		elif directive_value and not speaker:
			speaker = directive_value


class DialogLinePart:
	pass


class TextPart:
	extends DialogLinePart
	var text: String = ""

	func _init(text: String) -> void:
		self.text = text

	func _to_string() -> String:
		return "TextPart(%s)" % text


class DirectivePart:
	extends DialogLinePart
	var name: String
	var value: String

	func _init(name: String, value: String) -> void:
		self.name = name
		self.value = value

	func _to_string() -> String:
		return "DirectivePart(%s, %s)" % [name, value]
