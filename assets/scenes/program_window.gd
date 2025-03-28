class_name ProgramWindow extends Window

var program : NativeProgram

func populate(scene: PackedScene) -> void:
	program = scene.instantiate()
	program.populate(self)
	self.add_child(program)


func _ready() -> void:
	self.content_scale_factor = ProjectSettings.get_setting("display/window/stretch/scale")
	self.size *= content_scale_factor
	self.show()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_close_window"):
		self.close_requested.emit()
