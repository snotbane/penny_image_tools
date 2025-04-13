@tool class_name ParameterString extends Parameter

@export var _value : String :
	get: return $hbox/line_edit.text if self.find_child("line_edit") else ""
	set(val):
		if not self.find_child("line_edit"): return
		$hbox/line_edit.text = val
		$hbox/line_edit.tooltip_text = val

@export var allow_empty : bool = false


func _get_validation() -> String:
	if allow_empty or value != "": return ""
	return "String cannot be empty."
