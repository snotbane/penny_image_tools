class_name ImagePreview extends Control

var image_path : String :
	get: return $v_box_container/path_label.text if $v_box_container/path_label else ""
	set(value):
		if not $v_box_container/path_label: return
		$v_box_container/path_label.text = value

		refresh()
func set_image_path(path: String) -> void:
	image_path = path


var texture : Texture2D :
	get: return $v_box_container/panel_container/margin_container/preview_image.texture
	set(value): $v_box_container/panel_container/margin_container/preview_image.texture = value


func refresh() -> void:
	if not FileAccess.file_exists(image_path): texture = null; return

	var image := Image.new()
	var error := image.load(image_path)
	texture = ImageTexture.create_from_image(image) if error == OK else null
