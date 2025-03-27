@tool class_name ParameterNumeric extends ParameterBase

@export var min_value : float :
	get: return $spin_box.min_value if $spin_box else -1
	set(value):
		if not find_child("spin_box"): return
		$spin_box.min_value = value

@export var max_value : float :
	get: return $spin_box.max_value if $spin_box else -1
	set(value):
		if not find_child("spin_box"): return
		$spin_box.max_value = value

@export var value : float :
	get: return $spin_box.value if $spin_box else -1
	set(value):
		if not find_child("spin_box"): return
		$spin_box.value = value

@export var step : float :
	get: return $spin_box.step if $spin_box else -1
	set(value):
		if not find_child("spin_box"): return
		$spin_box.step = value


func _get_pref_value() -> Variant:
	return value

func update_children(__value: Variant) -> void:
	value = __value
