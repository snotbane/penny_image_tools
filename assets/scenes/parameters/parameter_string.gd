@tool class_name ParameterString extends ParameterBase

@export var text : String :
	get: return $line_edit.text if $line_edit else ""
	set(value):
		if find_child("line_edit") == null: return
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
