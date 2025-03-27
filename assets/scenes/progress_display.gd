@tool class_name ProgressDisplay extends Control

@export var label_text : String :
	get: return $hbox/label.text if self.is_inside_tree() else ""
	set(value):
		if not self.is_inside_tree(): return
		$hbox/label.text = value


@export var value : int :
	get: return $progress_bar.value if self.is_inside_tree() else 0
	set(value):
		if not self.is_inside_tree(): return
		$progress_bar.value = value
		$hbox/label_progress_done.text = str(int($progress_bar.value))


@export var max_value : int :
	get: return $progress_bar.max_value if self.is_inside_tree() else 0
	set(value):
		if not self.is_inside_tree(): return
		$progress_bar.max_value = value
		$hbox/label_progress_todo.text = str(int($progress_bar.max_value))


# @export var step : float :
# 	get: return $progress_bar.step if $progress_bar else 1
# 	set(value):
# 		if $progress_bar == null: return
# 		$progress_bar.step = value


func complete() -> void:
	self.value = self.max_value
