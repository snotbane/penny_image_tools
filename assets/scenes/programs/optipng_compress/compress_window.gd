extends ProgramWindow

@export_file("*.cfg") var config_path : String
@onready var config : ConfigFile = ConfigFile.new()

var preview_image : Image
var preview_texture : Texture2D

var _progress_path : String
var progress_path : String :
	get: return _progress_path
	set(value):
		if _progress_path == value: return
		_progress_path = value

		progress_path_changed.emit(_progress_path)

		preview_image = Image.new()
		var error := preview_image.load(_progress_path)

		if error != OK:	progress_image_changed.emit(null); print("Failed to load image %s" % _progress_path); return

		preview_texture = ImageTexture.create_from_image(preview_image)
		progress_image_changed.emit(preview_texture)


signal progress_path_changed(path: String)
signal progress_image_changed(texture: Texture2D)


var _progress_todo : int
@export var progress_todo : int :
	get: return _progress_todo
	set(value):
		if _progress_todo == value: return
		_progress_todo = value

		progress_todo_changed.emit(_progress_todo)
signal progress_todo_changed(value: int)

var _progress_done : int
@export var progress_done : int :
	get: return _progress_done
	set(value):
		if _progress_done == value: return
		_progress_done = value

		progress_done_changed.emit(_progress_done)
signal progress_done_changed(value: int)


func _ready() -> void:
	super._ready()
	config.load(config_path)
	config.set_value("output", "progress_path", "")
	config.set_value("input", "cancel", false)
	config.save(config_path)


func _process_execute(delta: float) -> void:
	config.load(config_path)
	progress_path = config.get_value("output", "progress_path")
	progress_todo = config.get_value("output", "progress_todo")
	progress_done = config.get_value("output", "progress_done")


func _execute_started() -> void:
	pass


func _execute_finished(code: int) -> void:
	if code == OK:
		progress_done = progress_todo


func _get_arguments() -> PackedStringArray:
	var result := super._get_arguments()
	result.push_back(ProjectSettings.globalize_path(config_path))
	return result


func cancel() -> void:
	super.cancel()
	config.set_value("input", "cancel", true)
	config.save(config_path)
