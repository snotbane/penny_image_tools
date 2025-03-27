class_name ImagePreview extends Control

var image_path : String :
	get: return $v_box_container/preview_path.text if $v_box_container/preview_path else ""
	set(value):
		if not $v_box_container/preview_path: return
		$v_box_container/preview_path.text = value

		if not FileAccess.file_exists(image_path): texture = null; return

		var image = Image.new()
		var error := image.load(image_path)
		texture = ImageTexture.create_from_image(image) if error == OK else null
func set_image_path(path: String) -> void:
		image_path = path

var texture : Texture2D :
	get: return $v_box_container/panel_container/margin_container/preview_image.texture
	set(value): $v_box_container/panel_container/margin_container/preview_image.texture = value
