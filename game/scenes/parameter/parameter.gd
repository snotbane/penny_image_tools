@tool class_name Parameter extends Control

const CONFIG_PATH := "user://prefs.cfg"
const SECTION_NAME := "persistent"
static var CONFIG := ConfigFile.new()

static func _static_init() -> void:
	var err := CONFIG.load(CONFIG_PATH)
	if err == ERR_DOES_NOT_EXIST:
		CONFIG.save(CONFIG_PATH)

@export var label_text : String :
	get: return $hbox/label.text if self.find_child("label") else ""
	set(value):
		if not self.find_child("label"): return
		$hbox/label.text = value

## If enabled, this value will be saved to a configuration file and loaded whenever a parameter of the same node name appears.
@export var persistent : bool

var argument : Variant

var argument_as_config_data : String :
	get: return str(argument)

func _ready() -> void:
	if persistent:
		load_persistent()


func load_persistent() -> void:
	if not CONFIG.has_section_key(SECTION_NAME, self.name): save_persistent()
	argument = CONFIG.get_value(SECTION_NAME, self.name)
	_load_persistent()
func _load_persistent() -> void:
	pass


func save_persistent() -> void:
	CONFIG.set_value(SECTION_NAME, self.name, self.argument_as_config_data)
	CONFIG.save(CONFIG_PATH)
	print()


func set_value(new_value: Variant) -> void:
	argument = new_value
	print("Set parameter value to " + str(argument))
