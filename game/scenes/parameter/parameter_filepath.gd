@tool class_name ParameterFilepath extends ParameterString

@export var file_mode : FileDialog.FileMode :
	get: return $file_dialog.file_mode if $file_dialog else FileDialog.FileMode.FILE_MODE_OPEN_ANY
	set(value):
		if not find_child("file_dialog"): return
		$file_dialog.file_mode = value

@export var access : FileDialog.Access :
	get: return $file_dialog.access if $file_dialog else FileDialog.Access.ACCESS_FILESYSTEM
	set(value):
		if not find_child("file_dialog"): return
		$file_dialog.access = value


func _get_validation() -> String:
	var super_result := super._get_validation()
	if super_result != "": return super_result
	return "" if FileAccess.file_exists(value) else "Filepath does not exist."
