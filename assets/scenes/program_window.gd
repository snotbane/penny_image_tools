@tool class_name ProgramWindow extends Window

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

var arguments : PackedStringArray :
	get:
		var result : PackedStringArray
		result.push_back(script_path_global)
		for e in parameters: result.push_back(e._get_arg_value())
		return result
func _get_arguments() -> PackedStringArray:
	return arguments



func _ready() -> void:
	config_path = "user://%s.cfg" % self.name

	if Engine.is_editor_hint(): return

	self.content_scale_factor = ProjectSettings.get_setting("display/window/stretch/scale")
	self.size *= content_scale_factor
	self.show()
	thread = Thread.new()

	refresh_title()



func _process(delta: float) -> void:
	if Engine.is_editor_hint(): return
	if is_executing:
		if thread.is_alive():
			refresh_title()
			self._process_execute(delta)
		else:
			var dir := DirAccess.open("user://")
			dir.remove(config_path)
			is_executing = false
			var code : int = thread.wait_to_finish()
			self._execute_finished(code)
			execute_finished.emit()


func _process_execute(delta: float) -> void:
	pass


func refresh_title() -> void:
	self.title = "PIT — %s" % self.program_name
	if thread.is_alive():
		self.title += " — %s" % get_duration_string(Time.get_ticks_msec() - execute_button.time_started)


func exit() -> void:
	self.terminate()
	self.hide()
	self.queue_free()


func execute():
	config = ConfigFile.new()
	config.save(config_path)
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
	if is_executing: $control/close_confirmation.show()
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
