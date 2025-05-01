@tool extends Parameter

@export var tab_container : TabContainer

@export_storage var _value : Dictionary :
	get:
		if not tab_container: return {}
		var result := {}
		result[&"current_tab"] = tab_container.current_tab
		for child in tab_container.get_children():
			result[child.name] = child.value
		return result
	set(val):
		if not tab_container: return
		tab_container.current_tab = val[&"current_tab"]
		for child in tab_container.get_children():
			if not val.has(child.name): continue
			child.value = val[child.name]

# func _get_validation() -> String:
# 	if not tab_container: return ""
# 	for child in tab_container.get_children():
# 		if child.value.is_empty(): continue
# 		return ""
# 	return "Remap must contain at least one color entry."
