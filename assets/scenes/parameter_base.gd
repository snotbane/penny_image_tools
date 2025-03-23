class_name ParameterBase extends Control

const PREFS_PATH := "user://prefs.cfg"
const SECTION_NAME := "all"
static var CONFIG := ConfigFile.new()

@export var save_to_prefs : bool

static func _static_init() -> void:
	var err := CONFIG.load(PREFS_PATH)
	if err != OK: return


static func get_pref_value(key: String) -> Variant:
	return CONFIG.get_value(SECTION_NAME, key)


func _ready() -> void:
	if save_to_prefs:
		if not CONFIG.has_section_key(SECTION_NAME, self.name):	update_prefs()
		update_children(CONFIG.get_value(SECTION_NAME, self.name))


func _get_arg_value() -> String: return "None"


func update_children(value: Variant) -> void:
	pass


func update_prefs() -> void:
	if save_to_prefs:
		CONFIG.set_value(SECTION_NAME, self.name, self._get_pref_value())
		CONFIG.save(PREFS_PATH)
func _get_pref_value() -> Variant: return null
