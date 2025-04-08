@tool class_name ParameterOption extends Parameter

var _options : PackedStringArray
@export var options : PackedStringArray :
	get:
		return _options
	set(value):
		_options = value

		if not self.find_child("option_button"): return

		$hbox/option_button.clear()
		for i in _options.size():
			$hbox/option_button.add_item(_options[i])


var _value : int
@export var value : int :
	get: return _value
	set(val):
		if not self.find_child("option_button"): return
		_value = clampi(val, -1, options.size() - 1)
		$hbox/option_button.selected = _value


var value_as_text : String :
	get: return _options[self.value] if value > -1 else ""


func _ready() -> void:
	options = options
	value = value
	super._ready()
