extends VBoxContainer

const COLOR_REMAP_SCENE := preload("res://game/scenes/parameter/color_remap/subparam_color_remap.tscn")

func add_color_remap() -> void:
	var node : Node = null
	for i in self.get_child_count():
		if self.get_child(-i-1) is not ColorRemapEntry: continue
		node = self.get_child(-i-1).duplicate()
		break
	if node == null:
		node = COLOR_REMAP_SCENE.instantiate()
	self.add_child(node)
	self.move_child($add_color, self.get_child_count() - 1)


func _on_add_color_pressed() -> void:
	add_color_remap()
