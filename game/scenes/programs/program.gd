class_name Program extends Control

static var BUS_DIR : DirAccess

static func _static_init() -> void:
	BUS_DIR = DirAccess.open("user://")

signal started
signal stop_requested
signal stopped


@export var print_output : bool
@export var identifier : StringName = &"program"
@export var program_name : String = "Program"
@export var program_nickname : String = "Program"
@export_file("*.py") var python_script_path : String
@export var parameters_container : Control
@export var target_parameter : ParameterString
@export var elements : Array[Control]
@export var execute_button : Button


var bus : ConfigFile
var bus_path : String
var thread : Thread
var window : ProgramWindow
var time_started : int

var _is_running : bool
var is_running : bool :
	get: return _is_running
	set(value):
		if _is_running == value: return
		_is_running = value

		execute_button.text = "Cancel" if _is_running else "Start"


func _ready() -> void:
	window = get_parent()
	window.close_requested.connect(on_close_requested)
	self.refresh_window_title()

	bus_path = "%s%s_%s.cfg" % [BUS_DIR.get_current_dir(), self.name, self.get_instance_id()]

	thread = Thread.new()


func _process(delta: float) -> void:
	if is_running:
		if thread.is_alive():
			self.refresh_window_title()
			self.refresh_elements()
		else:
			thread.wait_to_finish()
			thread_stopped()


func _exit_tree() -> void:
	BUS_DIR.remove(bus_path)


func add_to_queue() -> void:
	pass


func load_parameters(data: Dictionary) -> void:
	for i in parameters_container.get_children():
		if not data.has(i.name): continue
		i.value = data[i.name]


func save_parameters() -> Dictionary:
	var result : Dictionary = {}
	for i in parameters_container.get_children():
		result[i.name] = i.value
	return result


func get_python_arguments() -> PackedStringArray:
	var result : PackedStringArray
	result.push_back(get_python_path(python_script_path))
	result.push_back(ProjectSettings.globalize_path(bus_path))
	print("Arguments:")
	for i in parameters_container.get_children():
		if i is not Parameter: continue
		result.push_back(i.value_as_python_argument)
		print("%s : '%s'" % [i.name, i.value_as_python_argument])
	return result


func get_progress() -> float:
	return 0.0


func start() -> void:
	if is_running: return
	is_running = true
	time_started = Time.get_ticks_msec()

	bus = ConfigFile.new()
	for i in elements: bus.set_value("output", i.name, i.value)
	bus.save(bus_path)

	started.emit()
	thread.start(python.bind(Parameter.get_persistent_parameter(&"python_path"), get_python_arguments()))


func stop() -> void:
	if not is_running: return

	bus.set_value("input", "stop", true)
	bus.save(bus_path)
	stop_requested.emit()


func thread_stopped() -> void:
	refresh_elements()
	is_running = false
	if not OS.is_debug_build():
		BUS_DIR.remove(bus_path)
		bus = null
	stopped.emit()


func python(python_path: String, args: PackedStringArray) -> int:
	var output : Array
	var result : int = OS.execute(python_path, args, output, print_output)
	if print_output: for e in output: print(e)
	return result


func on_close_requested() -> void:
	if is_running: $close_confirmation.show()
	else: self.force_close_window()

func force_close_window() -> void:
	self.stop()
	window.hide()
	window.queue_free()


func refresh_elements() -> void:
	bus.load(bus_path)
	for i in elements:
		if not i.has_method(&"set_value"): continue
		i.call(&"set_value", bus.get_value("output", i.name))
	_refresh_elements()
func _refresh_elements() -> void:
	pass


func refresh_window_title() -> void:
	window.title = "PIT — %s" % self.program_name
	if thread and thread.is_alive():
		window.title += " — %s" % get_duration_string(Time.get_ticks_msec() - time_started)

static func get_duration_string(msec: int) -> String:
	var total_seconds : int = msec / 1000
	var seconds : int = total_seconds % 60
	var minutes : int = total_seconds / 60
	var hours : int = total_seconds / 3600

	if hours > 0:
		return "%02d:%02d:%02d" % [hours, minutes, seconds]
	else:
		return "%02d:%02d" % [minutes, seconds]


func _on_start_button_pressed() -> void:
	if is_running:
		stop()
	else:
		start()


static func get_python_path(path: String) -> String:
	if OS.has_feature("editor"):
		return ProjectSettings.globalize_path(path)
	else:
		var result : String = path.substr(path.rfind("/") + 1)
		return OS.get_executable_path().get_base_dir().path_join("python").path_join(result)
