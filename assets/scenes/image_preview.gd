class_name ImagePreview extends Control

@onready var label : Label = $v_box_container/preview_path

var image_path : String :
	get: return label.text if label else ""
	set(value):
		if not label: return
		label.text = value

		refresh_texture()
func set_image_path(path: String) -> void:
		image_path = path

var texture : Texture2D :
	get: return $v_box_container/panel_container/margin_container/preview_image.texture
	set(value): $v_box_container/panel_container/margin_container/preview_image.texture = value


func refresh_texture() -> void:
	if not FileAccess.file_exists(image_path): texture = null; return

	var image = Image.new()
	var error := image.load(image_path)
	texture = ImageTexture.create_from_image(image) if error == OK else null
