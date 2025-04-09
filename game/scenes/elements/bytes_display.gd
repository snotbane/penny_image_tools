@tool extends HBoxContainer

@export var program : Program

@export var label_text : String = "Bytes" :
	get: return $label.text if $label else ""
	set(value):
		if not self.is_inside_tree(): return
		$label.text = value

var _value : int
@export var value : int :
	get: return _value
	set(value):
		_value = value
		$value_label.text = bytes_to_string(_value)
func set_value(val: int) -> void:
	value = val


func add(bytes: int) -> void:
	value += bytes

func clear() -> void:
	value = 0


static func bytes_to_string(bytes: int) -> String:
	if bytes < 1024:
		return str(bytes) + " B"
	if bytes < 1024 * 1024:
		return "%.2f KB" % (float(bytes) / 1024.0)
	if bytes < 1024 * 1024 * 1024:
		return "%.2f MB" % (float(bytes) / (1024.0 * 1024.0))
	return "%.2f GB" % (float(bytes) / (1024.0 * 1024.0 * 1024.0))
