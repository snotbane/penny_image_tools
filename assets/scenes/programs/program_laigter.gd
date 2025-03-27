@tool extends Program

@export var source_image_preview : ImagePreview
@export var target_image_preview : ImagePreview

@export var progress_display : ProgressDisplay

func _process_execute(delta: float) -> void:
	source_image_preview.image_path = config.get_value("output", "source_preview", "")
	target_image_preview.image_path = config.get_value("output", "target_preview", "")
	progress_display.value = config.get_value("output", "progress_done", 0)
	progress_display.max_value = config.get_value("output", "progress_todo", 0)


func _execute_finished(code: int) -> void:
	if code == OK:
		progress_display.complete()
