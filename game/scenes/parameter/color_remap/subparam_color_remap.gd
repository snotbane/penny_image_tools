@tool class_name SubparameterColorRemap extends Parameter

@export var _value : Array[Color] :
	get: return [a_color, b_color]
	set(val):
		a_color = val[0]
		b_color = val[1]

@export var a_color : Color :
	get: return $h_box_container/a.color if find_child("a") else Color.BLACK
	set(val):
		if not find_child("a"): return
		$h_box_container/a.color = val

@export var b_color : Color :
	get: return $h_box_container/b.color if find_child("b") else Color.BLACK
	set(val):
		if not find_child("b"): return
		$h_box_container/b.color = val
