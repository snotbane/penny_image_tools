@tool extends Program

@export var source_image_preview : ImagePreview
@export var target_image_preview : ImagePreview

@export var progress_bar : ProgressBar
@export var progress_done_label : Label
var _progress_done : int
var progress_done : int :
	get: return _progress_done
	set(value):
		if _progress_done == value: return
		_progress_done = value

		progress_bar.value = _progress_done
		progress_done_label.text = str(_progress_done)

@export var progress_todo_label : Label
var _progress_todo : int
var progress_todo : int :
	get: return _progress_todo
	set(value):
		if _progress_todo == value: return
		_progress_todo = value

		progress_bar.max_value = _progress_todo
		progress_todo_label.text = str(_progress_todo)


func _process_execute(delta: float) -> void:
	source_image_preview.image_path = config.get_value("output", "source_preview", "")
	target_image_preview.image_path = config.get_value("output", "target_preview", "")
	progress_todo = config.get_value("output", "progress_todo", 0)
	progress_done = config.get_value("output", "progress_done", 0)
