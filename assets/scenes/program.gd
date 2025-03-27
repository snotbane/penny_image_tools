@tool class_name Program extends Control

static var config_dir : DirAccess

static func _static_init() -> void:
	config_dir = DirAccess.open("user://")

const PYTHON_VENV_PATH : String = "res://bin/python"
var python_venv_path_global : String :
	get: return actually_globalize_path(PYTHON_VENV_PATH)

signal execute_started
signal execute_finished

@export var program_name : String = "Program"
@export_file("*.py") var script_path : String
var script_path_global : String :
	get: return actually_globalize_path(script_path)
@export var parameters : Array[ParameterBase]
@export var execute_button : Button

var config : ConfigFile
var config_path : String
var thread : Thread
var is_executing : bool
var window : ProgramWindow

var arguments : PackedStringArray :
	get:
		var result : PackedStringArray
		result.push_back(script_path_global)
		for e in parameters: result.push_back(e._get_arg_value())
		return result
func _get_arguments() -> PackedStringArray:
	return arguments


func populate(__window: ProgramWindow) -> void:
	window = __window
	window.close_requested.connect(_on_close_requested)
	refresh_window_title()


func _ready() -> void:
	if Engine.is_editor_hint(): return
	# self.set_anchors_preset(Control.LayoutPreset.PRESET_FULL_RECT)

	config_path = "%s/%s.cfg" % [config_dir.get_current_dir(), self.name]
	config = ConfigFile.new()
	config.save(config_path)

	thread = Thread.new()


func _process(delta: float) -> void:
	if Engine.is_editor_hint(): return
	if is_executing:
		if thread.is_alive():
			refresh_window_title()
			config.load(config_path)
			self._process_execute(delta)
		else:
			remove_config()
			is_executing = false
			var code : int = thread.wait_to_finish()
			self._execute_finished(code)
			execute_finished.emit()


func _process_execute(delta: float) -> void:
	pass


func _exit_tree() -> void:
	remove_config()


func refresh_window_title() -> void:
	window.title = self._get_window_title()


func _get_window_title() -> String:
	var result := "PIT — %s" % self.program_name
	if thread and thread.is_alive():
		result += " — %s" % get_duration_string(Time.get_ticks_msec() - execute_button.time_started)
	return result


func remove_config() -> void:
	var dir := DirAccess.open("user://")
	dir.remove(config_path)


func exit() -> void:
	self.terminate()
	window.hide()
	window.queue_free()


func execute():
	self._execute_started()
	execute_started.emit()
	is_executing = true
	thread.start(_execute_python.bind(ParameterBase.get_pref_value("python_path"), _get_arguments()))


func _execute_started() -> void:
	pass


func _execute_finished(code: int) -> void:
	pass


func _execute_python(python: String, args: PackedStringArray):
	var output : Array
	var result : int = OS.execute(python, args, output, true)
	for e in output:
		print(e)
	return result


func terminate() -> void:
	if config == null: return
	config.set_value("input", "cancel", true)
	config.save(config_path)


func _on_close_requested() -> void:
	if is_executing: $close_confirmation.show()
	else: self.exit()


static func actually_globalize_path(path: String) -> String:
	if OS.has_feature("editor"):
		return ProjectSettings.globalize_path(path)
	else:
		var result : String = path.substr(path.find("//") + 2)
		return OS.get_executable_path().get_base_dir().path_join(result)


static func get_duration_string(msec: int) -> String:
	var total_seconds : int = msec / 1000
	var seconds : int = total_seconds % 60
	var minutes : int = total_seconds / 60
	var hours : int = total_seconds / 3600

	if hours > 0:
		return "%02d:%02d:%02d" % [hours, minutes, seconds]
	else:
		return "%02d:%02d" % [minutes, seconds]
