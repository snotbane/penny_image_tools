class_name ProgramWindow extends Window

var program : Program

func populate(scene: PackedScene) -> void:
	program = scene.instantiate()
	program.populate(self)
	self.add_child(program)


func _ready() -> void:
	self.content_scale_factor = ProjectSettings.get_setting("display/window/stretch/scale")
	self.size *= content_scale_factor
	self.show()
