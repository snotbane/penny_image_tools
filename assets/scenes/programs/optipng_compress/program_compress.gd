@tool extends Program


@export var source_image_preview : ImagePreview

@export var progress_display : ProgressDisplay

signal bytes_reduced_changed(bytes: int)


func _process_execute(delta: float) -> void:
	source_image_preview.image_path = config.get_value("output", "source_preview", "")

	var value_before : int = progress_display.value
	progress_display.value = config.get_value("output", "progress_done", 0)
	progress_display.max_value = config.get_value("output", "progress_todo", 0)
	if progress_display.value != value_before:
		bytes_reduced_changed.emit(config.get_value("output", "bytes_previous"))


func _execute_finished(code: int) -> void:
	if code == OK:
		progress_display.complete()


func _get_arguments() -> PackedStringArray:
	var result := super._get_arguments()
	result.push_back(ProjectSettings.globalize_path(config_path))
	return result
