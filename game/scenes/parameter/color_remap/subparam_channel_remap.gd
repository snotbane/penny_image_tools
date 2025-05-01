@tool extends PanelContainer

@export var enabled : bool :
	get: return $settings/enabled.value if find_child("enabled") else false
	set(val):
		if not find_child("enabled"): return
		$settings/enabled.value = val

@export var suffix : String :
	get: return $settings/suffix.value if find_child("suffix") else "_"
	set(val):
		if not find_child("suffix"): return
		$settings/suffix.value = val