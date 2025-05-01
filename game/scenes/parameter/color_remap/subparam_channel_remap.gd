@tool class_name SubparameterChannelRemap extends Parameter

const COLOR_REMAP_SCENE := preload("res://game/scenes/parameter/color_remap/subparam_color_remap.tscn")

@export var _value : Array :
	get:
		var result : Array = []
		for child in $settings/colors.get_children():
			result.push_back(child.value)
		return result
	set(val):
		for child in $settings/colors.get_children():
			child.queue_free()
		for i in val:
			var node : SubparameterColorRemap = COLOR_REMAP_SCENE.instantiate()
			node.value = i
			$settings/colors.add_child(node)


func _on_add_button_pressed() -> void:
	var node : SubparameterColorRemap = COLOR_REMAP_SCENE.instantiate()
	$settings/colors.add_child(node)
