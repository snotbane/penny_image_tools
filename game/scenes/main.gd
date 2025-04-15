extends Control

var time_started


func _ready() -> void:
	self.get_viewport().get_window().close_requested.connect(close_requested)

	self.get_window().size = Vector2i(Parameter.get_global(&"all", &"window_size_x"), Parameter.get_global(&"all", &"window_size_y"))
	self.get_window().move_to_center()


func _process(delta: float) -> void:
	if $panel_container/margin_container/v_box_container/h_box_container/task_queue/panel_container/margin_container/task_tree.is_running:
		self.get_window().title = "%s — %s" % [ProjectSettings.get_setting("application/config/name"), Utils.get_duration_string(Time.get_ticks_msec() - time_started)]


func close_requested() -> void:
	if $panel_container/margin_container/v_box_container/h_box_container/task_queue/panel_container/margin_container/task_tree.is_running:
		$close_confirmation.show()
	else:
		quit()


func quit() -> void:
	Parameter.set_global(&"all", &"window_size_x", self.get_window().size.x)
	Parameter.set_global(&"all", &"window_size_y", self.get_window().size.y)
	self.get_tree().quit()


func _on_task_tree_started() -> void:
	time_started = Time.get_ticks_msec()
