class_name StageCommand
## Represents a command to apply changes to a stage.
## Commands are parsed from directives,
## e.g. [enter:Note] becomes a StageCommand with name "enter" and value "Note",
## and dialog in timeline source files is parsed into a command
## with name "dialog" and value the text.


static func from_directive(directive: Directive) -> StageCommand:
	var command: StageCommand
	match directive.name:
		"speaker":
			command = SpeakerCommand.new(directive.value)
		"dialog":
			command = DialogCommand.new(directive.value)
		"background":
			command = BackgroundCommand.new(directive.value)
		"enter":
			command = EnterCommand.new(directive)
		"exit":
			command = LeaveCommand.new(directive)

	if not command:
		assert("Unknown directive [%s:%s]" % [directive.name, directive.value])

	return command


class Directive:
	var name: String
	var value: String
	var args := {}

	func _init(name: String, value: String) -> void:
		self.name = name
		self.value = value

		var positional_arg_index := 0
		for value_part in value.split(",", false):
			var named_arg_parts := value_part.split("=", false)
			if named_arg_parts.size() == 2:
				var arg_name := named_arg_parts[0].strip_edges()
				var arg_value := named_arg_parts[1].strip_edges()
				args[arg_name] = arg_value
			else:
				args[positional_arg_index] = value_part.strip_edges()
				positional_arg_index += 1

	func get_required_arg(key: Variant) -> String:
		if not args.has(key):
			var message := (
				"Missing required argument '%s' for directive [%s:%s]" % [key, name, value]
			)
			push_error(message)
		return args[key]


class SpeakerCommand:
	extends StageCommand
	var speaker: String

	func _init(name: String) -> void:
		self.speaker = name


class DialogCommand:
	extends StageCommand
	var text: String

	func _init(text: String) -> void:
		self.text = text


class BackgroundCommand:
	extends StageCommand
	var background_name: String

	func _init(name: String) -> void:
		self.background_name = name


class EnterCommand:
	extends StageCommand
	var character_name: String
	var to_position: float
	var from_position: float
	var duration: float

	func _init(directive: Directive) -> void:
		self.character_name = directive.get_required_arg(0)
		self.to_position = directive.get_required_arg("to").to_float()
		self.from_position = directive.get_required_arg("from").to_float()
		self.duration = directive.get_required_arg("duration").to_float()


class LeaveCommand:
	extends StageCommand
	var character_name: String
	var by_position: float
	var duration: float

	func _init(directive: Directive) -> void:
		self.character_name = directive.get_required_arg(0)
		self.by_position = directive.get_required_arg("by").to_float()
		self.duration = directive.get_required_arg("duration").to_float()
