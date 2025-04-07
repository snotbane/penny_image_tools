@tool class_name ParameterBool extends Parameter

@export var toggled : bool :
	get: return $hbox/check_box.button_pressed if $hbox/check_box.button_pressed else false
	set(value):
		if not find_child("check_box"): return
		$hbox/check_box.button_pressed = value


func _load_persistent() -> void:
	toggled = argument
