class_name ColorRemapEntry extends PanelContainer

var stylebox : StyleBoxFlat :
	get: return self.get_theme_stylebox(&"panel")

var color : Color :
	get: return self.stylebox.bg_color
	set(value):
		self.stylebox.bg_color = value
		$hex_label.text = self.color.to_html(false)


func _ready() -> void:
	self.add_theme_stylebox_override(&"panel", self.get_theme_stylebox(&"panel").duplicate(true))
	color = color


func _on_color_picker_color_changed(_color: Color) -> void:
	color = _color
