class_name ProgramWindow extends Window

signal hidden

var program : Program
var show_on_ready : bool

func populate(scene: PackedScene, _show_on_ready: bool = false) -> void:
	program = scene.instantiate()
	self.add_child(program)
	show_on_ready = _show_on_ready


func _ready() -> void:
	self.content_scale_factor = ProjectSettings.get_setting("display/window/stretch/scale")
	self.size *= content_scale_factor

	if show_on_ready: self.show()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_close_window"):
		self.close_requested.emit()
