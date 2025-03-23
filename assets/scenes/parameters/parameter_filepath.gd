class_name ParameterFilepath extends ParameterString

func get_is_valid() -> bool:
	return DirAccess.dir_exists_absolute(text)


func open_file_dialog() -> void:
	$file_dialog.popup_centered_ratio(0.8)


func confirm_file_dialog() -> void:
	print($file_dialog.current_path)
	text = $file_dialog.current_path
