@tool class_name ParameterNumber extends Parameter

@export var min_value : float :
	get: return $hbox/spin_box.min_value if $hbox/spin_box else -1
	set(value):
		if not find_child("spin_box"): return
		$hbox/spin_box.min_value = value

@export var max_value : float :
	get: return $hbox/spin_box.max_value if $hbox/spin_box else -1
	set(value):
		if not find_child("spin_box"): return
		$hbox/spin_box.max_value = value

@export var value : float :
	get: return $hbox/spin_box.value if $hbox/spin_box else -1
	set(val):
		if not find_child("spin_box"): return
		$hbox/spin_box.value = val

@export var step : float :
	get: return $hbox/spin_box.step if $hbox/spin_box else -1
	set(value):
		if not find_child("spin_box"): return
		$hbox/spin_box.step = value
