extends Button

signal executed
signal canceled

var time_started : int
var time_stopped : int

func _ready() -> void:
	refresh_text()


func _toggled(toggled_on: bool) -> void:
	refresh_text()

	if button_pressed: time_started = Time.get_ticks_msec()
	else: time_stopped = Time.get_ticks_msec()

	(executed if button_pressed else canceled).emit()


func refresh_text() -> void:
	self.text = "Cancel" if button_pressed else "Execute"

