@tool class_name ImagePreview extends Control

@export var label : Label :
	get: return find_child("path_label")

@export var value : String :
	get: return label.text if label else ""
	set(val):
		if not label or value == val: return
		label.text = val

		refresh()
func set_value(val: String) -> void:
	value = val


var texture : Texture2D :
	get: return $v_box_container/margin_container/texture_rect.texture
	set(value): $v_box_container/margin_container/texture_rect.texture = value


func refresh() -> void:
	if not FileAccess.file_exists(value): texture = null; return

	var image := Image.new()
	var error := image.load(value)
	texture = ImageTexture.create_from_image(image) if error == OK else null


func clear() -> void:
	value = ""
