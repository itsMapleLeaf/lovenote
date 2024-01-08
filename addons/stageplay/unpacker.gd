@tool
class_name Unpacker

var _data: Variant
var _error_prefix: String
var _path: Array = []

var _data_type_string: String:
	get: return type_string(typeof(_data))

var _path_string: String:
	get: return ":".join(_path)


func _init(data: Variant, error_prefix: String, path: Array) -> void:
	_data = data
	_error_prefix = error_prefix
	_path = path


static func from(data: Variant) -> Unpacker:
	return Unpacker.new(data, "failed to unpack", [])


func with_prefix(prefix: String) -> Unpacker:
	_error_prefix = prefix
	return self


func _to_string() -> String:
	if _path.is_empty():
		return "Unpacker[%s](%s)" % [_data_type_string, _data]
	else:
		return "Unpacker[%s at %s](%s)" % [_data_type_string, _path_string, _data]


func _print_expected_error(expected: String) -> void:
	printerr("%s%s: expected %s, received %s with value: %s" % [
		_error_prefix,
		" at " + _path_string if not _path.is_empty() else "",
		expected,
		_data_type_string,
		_data,
	])


func dict(fallback := {}) -> Dictionary:
	if _data is Dictionary: return _data
	_print_expected_error("dictionary")
	return fallback


func at(key: StringName) -> Unpacker:
	return Unpacker.new(dict().get(key), _error_prefix, _path + [key])


func array() -> Array[Unpacker]:
	if not _data is Array:
		_print_expected_error("array")
		return []

	var data: Array = _data
	var result: Array[Unpacker] = []
	for index in data.size():
		result.append(Unpacker.new(data[index], _error_prefix, _path + [index]))
	return result


func string(fallback := "") -> String:
	if _data is String: return _data
	_print_expected_error("string")
	return fallback


func int(fallback := 0) -> int:
	if _data is int: return _data
	_print_expected_error("int")
	return fallback


func float(fallback := 0.0) -> float:
	if _data is float: return _data
	_print_expected_error("float")
	return fallback

