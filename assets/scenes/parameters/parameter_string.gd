@tool class_name ParameterString extends ParameterBase

var text : String :
	get: return $line_edit.text
	set(value):
		$line_edit.tooltip_text = text

		if text == value: return
		$line_edit.text = value


func _ready():
	super._ready()
	text = text


func update_children(value: Variant) -> void:
	text = value

func _get_pref_value() -> Variant:
	return text

func _get_arg_value() -> String:
	return text
