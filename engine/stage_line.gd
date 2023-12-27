class_name StageLine

var directives: Array[StageDirective]
var snapshot: StageSnapshot


func _init(directives: Array[StageDirective], base_snapshot: StageSnapshot) -> void:
	self.directives = directives

	snapshot = base_snapshot.copy()
	snapshot.reset_dialog()
	snapshot.apply_directives(directives)


func _to_string() -> String:
	var data := {
		"directives": directives,
		"snapshot": snapshot,
	}
	return "StageLine(%s)" % data
