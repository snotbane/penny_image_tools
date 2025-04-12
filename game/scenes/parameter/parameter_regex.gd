@tool extends ParameterString


func _get_validation() -> String:
	var super_result := super._get_validation()
	if super_result != "": return super_result
	var regex := RegEx.create_from_string(value, false)
	return "" if regex.is_valid() else "RegEx is not valid."
