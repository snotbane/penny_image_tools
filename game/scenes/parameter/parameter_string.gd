@tool class_name ParameterString extends Parameter

@export var text : String :
	get: return $hbox/line_edit.text if self.find_child("line_edit") else ""
	set(value):
		if not self.find_child("line_edit"): return
		$hbox/line_edit.text = value

func _load_persistent() -> void:
	text = argument
