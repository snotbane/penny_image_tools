@tool class_name ParameterString extends Parameter

@export var value : String :
	get: return $hbox/line_edit.text if self.find_child("line_edit") else ""
	set(val):
		if not self.find_child("line_edit"): return
		$hbox/line_edit.text = val
