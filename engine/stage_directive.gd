class_name StageDirective
## Represents a command to apply changes to a stage.
## Commands are parsed from directives,
## e.g. [enter:Note] becomes a StageCommand with directive_name "enter" and directive_value "Note",
## and dialog in timeline source files is parsed into a command
## with directive_name "dialog" and directive_value the text.

var directive_name: String
var directive_value: String
var args := {}


func _init(name: String, value: String) -> void:
	self.directive_name = name
	self.directive_value = value

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


func parse() -> StageDirective:
	var directive: StageDirective

	match directive_name:
		"speaker":
			directive = SpeakerDirective.new(directive_value)
		"dialog":
			directive = DialogDirective.new(directive_value)
		"background":
			directive = BackgroundDirective.new(directive_value)
		"enter":
			directive = EnterDirective.new()
		"leave":
			directive = LeaveDirective.new()

	if not directive:
		assert("Unknown directive [%s:%s]" % [directive.directive_name, directive.directive_value])

	return directive


func get_required_arg(key: Variant) -> String:
	if not args.has(key):
		var message := (
			"Missing required argument '%s' for directive [%s:%s]"
			% [key, directive_name, directive_value]
		)
		assert(message)
	return args[key]


class SpeakerDirective:
	extends StageDirective
	var speaker: String

	func _init(speaker: String) -> void:
		self.speaker = speaker


class DialogDirective:
	extends StageDirective
	var text: String

	func _init(text: String) -> void:
		self.text = text


class BackgroundDirective:
	extends StageDirective
	var background_name: String

	func _init(name: String) -> void:
		self.background_name = name


class EnterDirective:
	extends StageDirective
	var character_name: String
	var to_position: float
	var from_position: float
	var duration: float

	func _init() -> void:
		self.character_name = get_required_arg(0)
		self.to_position = get_required_arg("to").to_float()
		self.from_position = get_required_arg("from").to_float()
		self.duration = get_required_arg("duration").to_float()


class LeaveDirective:
	extends StageDirective
	var character_name: String
	var by_position: float
	var duration: float

	func _init() -> void:
		self.character_name = get_required_arg(0)
		self.by_position = get_required_arg("by").to_float()
		self.duration = get_required_arg("duration").to_float()
