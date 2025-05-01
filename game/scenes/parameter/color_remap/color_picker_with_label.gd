extends ColorPickerButton

# @onready var label : Label = $label

func _ready() -> void:
	_on_color_changed(color)


func _on_color_changed(_color: Color) -> void:
	$label.text = _color.to_html(edit_alpha).to_upper()
