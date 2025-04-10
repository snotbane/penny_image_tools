@tool class_name ParameterOption extends Parameter

var _options : PackedStringArray
@export var options : PackedStringArray :
	get:
		return _options
	set(val):
		_options = val

		if not self.find_child("option_button"): return

		$hbox/option_button.clear()
		for i in _options.size():
			$hbox/option_button.add_item(_options[i])


var __value : int
@export var _value : int :
	get: return __value
	set(val):
		if not self.find_child("option_button"): return
		__value = clampi(val, -1, options.size() - 1)
		$hbox/option_button.selected = __value


var value_as_text : String :
	get: return _options[self._value] if _value > -1 else ""


func _ready() -> void:
	options = options
	_value = _value
	super._ready()
