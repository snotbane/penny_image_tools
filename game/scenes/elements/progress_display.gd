@tool extends Control

@export var label_text : String = "Completed" :
	get: return $progress_bar/margin_container/h_box_container/label.text if self.find_child("label") else ""
	set(value):
		if not self.find_child("label"): return
		$progress_bar/margin_container/h_box_container/label.text = value


@export var value : int = 0 :
	get: return $progress_bar.value if $progress_bar else 0
	set(val):
		if not self.is_inside_tree(): return
		$progress_bar.value = val
		refresh_value_label()
func set_value(val: int) -> void:
	value = val


@export var max_value : int = 1 :
	get: return $progress_bar.max_value if $progress_bar else 0
	set(value):
		if not self.is_inside_tree(): return
		$progress_bar.max_value = value
		refresh_value_label()


func refresh_value_label() -> void:
	$progress_bar/margin_container/h_box_container/value_label.text = "%s / %s" % [str(int($progress_bar.value)), str(int($progress_bar.max_value))]


func complete() -> void:
	self.value = self.max_value
