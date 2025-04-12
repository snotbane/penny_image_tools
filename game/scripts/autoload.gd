extends Node

const UI_SCALE_VALUES : PackedFloat64Array = [
	0.25,
	0.50,
	0.75,
	1.0,
	1.333,
	1.5,
	2.0,
	3.0,
	4.0
]
const UI_SCALE_SPEED : float = 20.0


func _process(delta: float) -> void:
	self.get_viewport().get_window().content_scale_factor = lerpf(self.get_viewport().get_window().content_scale_factor, ProjectSettings.get_setting("display/window/stretch/scale"), min(UI_SCALE_SPEED * delta, 1.0))


func _input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_scale_up"):
		Parameter.set_persistent_parameter(&"all", &"ui_scale", clamp(Parameter.get_persistent_parameter(&"all", &"ui_scale") + 1, 0, UI_SCALE_VALUES.size() - 1))
		refresh_ui_scale()
	if event.is_action_pressed(&"ui_scale_down"):
		Parameter.set_persistent_parameter(&"all", &"ui_scale", clamp(Parameter.get_persistent_parameter(&"all", &"ui_scale") - 1, 0, UI_SCALE_VALUES.size() - 1))
		refresh_ui_scale()


func refresh_ui_scale() -> void:
	ProjectSettings.set_setting("display/window/stretch/scale", UI_SCALE_VALUES[Parameter.get_persistent_parameter(&"all", &"ui_scale")])
