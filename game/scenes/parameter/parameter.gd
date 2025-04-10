@tool class_name Parameter extends Control

const CONFIG_PATH := "user://prefs.cfg"
const SECTION_NAME := "persistent"
static var CONFIG := ConfigFile.new()

static func _static_init() -> void:
	var err := CONFIG.load(CONFIG_PATH)
	if err != OK:
		CONFIG.save(CONFIG_PATH)


static func get_persistent_parameter(key: StringName) -> Variant:
	return CONFIG.get_value(SECTION_NAME, key)


@export var label_text : String :
	get: return $hbox/label.text if self.find_child("label") else ""
	set(value):
		if not self.find_child("label"): return
		$hbox/label.text = value

## If enabled, this value will be saved to a configuration file and loaded whenever a parameter of the same node name appears.
var _persistent : bool
@export var persistent : bool :
	get: return _persistent
	set(value):
		if _persistent == value: return
		_persistent = value

		if Engine.is_editor_hint(): return
		if _persistent:
			save_persistent()
		else:
			clear_persistent()

@export_tool_button("Clear Persistent") var clear_persistent_ := clear_persistent

@export_tool_button("Clear Persistent (All)") var clear_all_persistent_data := func() -> void:
	CONFIG = ConfigFile.new()
	CONFIG.save(CONFIG_PATH)

var argument : Variant

var argument_as_config_data : Variant :
	get: return argument

var argument_as_python_argument : String :
	get:
		# if argument is bool:
		# 	return "True" if argument else "False"
		if argument is float and fmod(argument, 1.0) == 0.0:
			return str(int(argument))
		return str(argument)


func _ready() -> void:
	argument = get(&"value")
	if Engine.is_editor_hint(): return
	if persistent: load_persistent()


func set_value(new_value: Variant) -> void:
	argument = new_value
	if persistent: save_persistent()


func load_persistent() -> void:
	if not CONFIG.has_section_key(SECTION_NAME, self.name):
		save_persistent()
	argument = CONFIG.get_value(SECTION_NAME, self.name)
	if argument == null: return
	set(&"value", argument)
	_load_persistent()
func _load_persistent() -> void:
	pass


func save_persistent() -> void:
	CONFIG.set_value(SECTION_NAME, self.name, self.argument_as_config_data)
	CONFIG.save(CONFIG_PATH)


func clear_persistent() -> void:
	CONFIG.set_value(SECTION_NAME, self.name, null)
	CONFIG.save(CONFIG_PATH)
