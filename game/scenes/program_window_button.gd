extends Button

func _pressed() -> void:
	var task := Task.new(self.name)
	TaskQueue.inst.add(task)
	task.open(self.get_tree())
