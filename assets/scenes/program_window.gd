class_name ProgramWindow extends Control

const PYTHON_VENV_PATH : String = "res://bin/python"
var python_venv_path_global : String :
	get: return actually_globalize_path(PYTHON_VENV_PATH)

signal exited
signal execute_started
signal execute_finished

@export_file("*.py") var script_path : String
var script_path_global : String :
	get: return actually_globalize_path(script_path)

@export var parameters : Array[ParameterBase]
@export var previews : Array[Node]

var arguments : PackedStringArray :
	get:
		var result : PackedStringArray
		result.push_back(script_path_global)
		for e in parameters: result.push_back(e._get_arg_value())
		return result
func _get_arguments() -> PackedStringArray:
	return arguments


@onready var thread : Thread = Thread.new()

var is_executing : bool

func _ready() -> void: pass

func _process(delta: float) -> void:
	if is_executing:
		if thread.is_alive():
			_process_execute(delta)
			for e in previews: e._process_execute(delta)
		else:
			is_executing = false
			var code : int = thread.wait_to_finish()
			self._execute_finished(code)
			for e in previews: e._execute_finished(code)
			execute_finished.emit()


func _process_execute(delta: float) -> void:
	pass


func exit() -> void:
	exited.emit()


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


func cancel() -> void:
	pass


static func actually_globalize_path(path: String) -> String:
	if OS.has_feature("editor"):
		return ProjectSettings.globalize_path(path)
	else:
		var result : String = path.substr(path.find("//") + 2)
		return OS.get_executable_path().get_base_dir().path_join(result)
