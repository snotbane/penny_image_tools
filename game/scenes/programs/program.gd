class_name Program extends Control

const PLAY_ICON : Texture2D = preload("res://game/icons/Play.svg")
const STOP_ICON : Texture2D = preload("res://game/icons/Stop.svg")
const RESET_ICON : Texture2D = preload("res://game/icons/Reload.svg")

static var BUS_DIR : DirAccess

static func _static_init() -> void:
	BUS_DIR = DirAccess.open("user://")

signal started
signal stop_requested
signal stopped
signal succeeded
signal failed
signal parameters_changed

@export var print_output : bool
@export var identifier : StringName = &"program"
@export var program_name : String = "Program"
@export var program_nickname : String = "Program"
@export_file("*.py") var python_script_path : String
@export var parameters_container : Control
@export var target_parameter : ParameterString
@export var progress_display : ProgressDisplay
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

		execute_button.text = "Stop" if _is_running else "Run"
		execute_button.icon = STOP_ICON if _is_running else PLAY_ICON


var temp_folder_path : String :
	get: return ProjectSettings.globalize_path("user://tmp/")


func _ready() -> void:
	window = get_parent()
	window.close_requested.connect(on_close_requested)
	self.refresh_window_title()

	for i in parameters_container.get_children():
		if i is not Parameter: continue
		i.value_changed.connect(parameters_changed.emit.unbind(1))

	bus_path = "%s%s_%s.cfg" % [BUS_DIR.get_current_dir(), self.name, self.get_instance_id()]

	thread = Thread.new()


func _process(delta: float) -> void:
	if is_running:
		if thread.is_alive():
			self.refresh_window_title()
			self.refresh_elements()
		else:
			thread_stopped()

func _exit_tree() -> void:
	BUS_DIR.remove(bus_path)


func add_to_queue() -> void:
	var task := Task.new()
	task.populate_from_program(self)
	TaskQueue.inst.add(task)
	on_close_requested()


func get_task_comment() -> String:
	return self.program_nickname


func load_parameters(data: Dictionary) -> void:
	for i in parameters_container.get_children():
		if i is not Parameter: continue
		if not data.has(i.name): continue
		i.value = data[i.name]


func save_parameters() -> Dictionary:
	var result : Dictionary = {}
	for i in parameters_container.get_children():
		if i is not Parameter: continue
		# if i.persist: continue
		result[i.name] = i.value
	return result


func get_python_arguments() -> PackedStringArray:
	var result : PackedStringArray
	result.push_back(get_python_path(python_script_path))
	result.push_back(ProjectSettings.globalize_path(bus_path))
	for i in parameters_container.get_children():
		if i is not Parameter: continue
		if i.ignore: continue
		result.push_back(i.value_as_python_argument)
	if self.print_output:
		print("%s args: %s" % [self.identifier, result])
	return result


func start() -> void:
	if is_running: return
	is_running = true
	time_started = Time.get_ticks_msec()

	bus = ConfigFile.new()
	for i in elements: bus.set_value("output", i.name, i.value)
	bus.save(bus_path)

	started.emit()
	thread.start(python.bind(Parameter.get_global(&"all", &"python_path"), get_python_arguments()))


func stop() -> void:
	if not is_running: return

	bus.set_value("input", "stop", true)
	bus.save(bus_path)
	stop_requested.emit()


func thread_stopped() -> void:
	var code : int = thread.wait_to_finish()
	refresh_elements()
	is_running = false
# if not OS.is_debug_build():
	BUS_DIR.remove(bus_path)
	bus = null
	stopped.emit()
	if code == OK: succeeded.emit()
	else: failed.emit()


func python(python_path: String, args: PackedStringArray) -> int:
	var output : Array
	var result : int = OS.execute(python_path, args, output, print_output)
	if print_output: for e in output: print(e)
	return result


func on_close_requested() -> void:
	if window.visible:
		window.hide()
		window.hidden.emit()
		self.get_tree().root.grab_focus()
	if not is_running:
		window.queue_free()


func force_close_window() -> void:
	self.stop()
	if window.visible:
		self.get_tree().root.grab_focus()
		window.hide()
		window.hidden.emit()
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
	window.title = "%s — %s" % [ProjectSettings.get_setting("application/config/name"), self.program_nickname]
	if thread and thread.is_alive():
		window.title += " — %s" % Utils.get_duration_string(Time.get_ticks_msec() - time_started)


func get_source_target_diff_path() -> String:
	var source : String = parameters_container.find_child("source").value
	var target : String = parameters_container.find_child("target").value

	if source == "": return target

	var result : String
	while source != "":
		var source_snip := source.substr(source.rfind("/"))
		var target_snip := target.substr(target.rfind("/"))

		result = target_snip.path_join(result) if result else target_snip

		if source_snip == target_snip: break

		source = source.substr(0, source.rfind("/"))
		target = target.substr(0, target.rfind("/"))

	return result


func _on_start_button_pressed() -> void:
	if is_running:	stop()
	else:			start()


static func get_python_path(path: String) -> String:
	if OS.has_feature("editor"):
		return ProjectSettings.globalize_path(path)
	else:
		var result : String = path.substr(path.rfind("/") + 1)
		return OS.get_executable_path().get_base_dir().path_join("python").path_join(result)
