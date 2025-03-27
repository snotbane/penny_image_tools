@tool class_name ParameterEnum extends ParameterBase

var _options : PackedStringArray
@export var options : PackedStringArray :
	get:
		return _options
	set(value):
		_options = value

		if not self.is_inside_tree(): return

		$option_button.clear()
		for i in _options.size():
			$option_button.add_item(_options[i])


var _value : int
@export var value : int :
	get: return _value
	set(val):
		_value = clampi(val, -1, options.size() - 1)
		if not self.is_inside_tree(): return
		$option_button.selected = _value


@export var value_as_text : String :
	get: return _options[self.value] if value > -1 else ""


func _ready() -> void:
	options = options
	value = value
	super._ready()


func _get_pref_value() -> Variant:
	return $option_button.selected

func update_children(__value: Variant) -> void:
	value = __value

