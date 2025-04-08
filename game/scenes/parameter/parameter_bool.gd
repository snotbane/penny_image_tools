@tool class_name ParameterBool extends Parameter

@export var value : bool :
	get: return $hbox/check_box.button_pressed if $hbox/check_box else false
	set(val):
		argument = val
		if not find_child("check_box"): return
		$hbox/check_box.button_pressed = val
