class_name NativeProgram extends Control

signal execute_started
signal execute_stopped

@export var print_output : bool

@export var program_name : String = "Program"
@export var program_nickname : String = "Program"
@export var parameters_container : Control
@export var execute_button : Button

var parameters : Array[ParameterBase]
var thread : Thread
var window : ProgramWindow
var is_executing : bool


func _ready() -> void:
	parameters = []
	for child in parameters_container.get_children():
		if child is not ParameterBase: continue
		parameters.push_back(child)
	thread = Thread.new()


func _process(delta: float) -> void:
	if thread.is_alive():
		self.refresh_window_title()
		self._execute_process(delta)
	else:
		self.terminate()
func _execute_process(delta: float) -> void:
	pass


func populate(_window: ProgramWindow) -> void:
	window = _window
	window.close_requested.connect(_on_close_requested)
	refresh_window_title()


func execute() -> void:
	if is_executing: return
	is_executing = true

	_execute_started()
	execute_started.emit()
	thread.start(_program.bind(_get_arguments()))


func terminate() -> void:
	if not is_executing: return
	is_executing = false

	var result : Variant = thread.wait_to_finish()
	_execute_stopped(result)
	execute_stopped.emit()


func _execute_started() -> void:
	pass


func _execute_stopped(result: Variant) -> void:
	pass


func _program(args: Array) -> Variant:
	return 0


func _get_arguments() -> Array:
	var result : Array = []
	for param in parameters:
		result.push_back(param._get_arg_value())
	return result


func close_window() -> void:
	self.terminate()
	window.hide()
	window.queue_free()


func refresh_window_title() -> void:
	window.title = self._get_window_title()

func _get_window_title() -> String:
	var result := "PIT — %s" % self.program_name
	if thread and thread.is_alive():
		result += " — %s" % get_duration_string(Time.get_ticks_msec() - execute_button.time_started)
	return result


func _on_close_requested() -> void:
	if is_executing: $close_confirmation.show()
	else: self.close_window()


static func get_duration_string(msec: int) -> String:
	var total_seconds : int = msec / 1000
	var seconds : int = total_seconds % 60
	var minutes : int = total_seconds / 60
	var hours : int = total_seconds / 3600

	if hours > 0:
		return "%02d:%02d:%02d" % [hours, minutes, seconds]
	else:
		return "%02d:%02d" % [minutes, seconds]
