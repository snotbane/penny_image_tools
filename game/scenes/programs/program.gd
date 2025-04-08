class_name Program extends Control

signal started
signal stopped

@export var print_output : bool
@export var program_name : String = "Program"
@export var program_nickname : String = "Program"
@export var parameters_container : Control
@export var execute_button : Button


var thread := Thread.new()
var window : ProgramWindow


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


func start() -> void:
	is_running = true
	started.emit()
	pass

func stop() -> void:
	is_running = false
	stopped.emit()
	pass


func on_close_requested() -> void:
	if is_running: $close_confirmation.show()
	else: self.force_close_window()

func force_close_window() -> void:
	window.hide()
	window.queue_free()

func refresh_window_title() -> void:
	window.title = "PIT — %s" % self.program_name
	if thread and thread.is_alive():
		window.title += " — %s" % get_duration_string(Time.get_ticks_msec() - execute_button.time_started)

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
