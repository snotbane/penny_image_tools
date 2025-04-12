extends Control


func _ready() -> void:
	self.get_viewport().get_window().close_requested.connect(close_requested)


func close_requested() -> void:
	if $panel_container/margin_container/v_box_container/h_box_container/task_queue/panel_container/margin_container/task_tree.is_running:
		$close_confirmation.show()
	else:
		quit()


func quit() -> void:
	self.get_tree().quit()
