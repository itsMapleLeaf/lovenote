class_name StageCommand
## Represents a command to apply changes to a stage.
## Commands are parsed from directives,
## e.g. [enter:Note] becomes a StageCommand with name "enter" and value "Note",
## and dialog in timeline source files is parsed into a command
## with name "dialog" and value the text.

var name: String
var value: String
var args: Dictionary = {}


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
		var message := "Missing required argument '%s' for directive [%s:%s]" % [key, name, value]
		push_error(message)
	return args[key]


func _to_string() -> String:
	var data := {
		"name": name,
		"args": args,
	}
	return "DirectivePart(%s)" % data
