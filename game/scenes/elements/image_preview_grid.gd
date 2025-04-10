extends GridContainer

const image_preview_scene : PackedScene = preload("res://game/scenes/elements/image_preview.tscn")

var previews : Dictionary

func update_image(path: String) -> void:
	if previews.has(path):
		previews[path].refresh()
	else:
		var preview : ImagePreview = image_preview_scene.instantiate()
		# preview.label.visible = false
		self.add_child(preview)

		previews[path] = preview
		previews[path].value = path

		self.columns = ceili(sqrt(previews.size()))


func clear() -> void:
	previews.clear()
	for i in self.get_children():
		i.queue_free()

