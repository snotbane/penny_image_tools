@tool class_name Parameter extends Control

const CONFIG_PATH := "user://prefs.cfg"
static var CONFIG := ConfigFile.new()

static func _static_init() -> void:
	var err := CONFIG.load(CONFIG_PATH)
	if err != OK:
		CONFIG.save(CONFIG_PATH)


static func get_persistent_parameter(section: StringName, key: StringName, default: Variant = null) -> Variant:
	return CONFIG.get_value(section, key, default)


static func set_persistent_parameter(section: StringName, key: StringName, val: Variant) -> void:
	CONFIG.set_value(section, key, val)
	CONFIG.save(CONFIG_PATH)


signal value_changed(val: Variant)


@export var label_text : String :
	get: return $hbox/label.text if self.find_child("label") else ""
	set(value):
		if not self.find_child("label"): return
		$hbox/label.text = value


var _normal_tooltip : String
@export_multiline var normal_tooltip : String :
	get: return _normal_tooltip
	set(value):
		if _normal_tooltip == value: return
		_normal_tooltip = value
		refresh_tooltip()

var _validation : String
var validation : String :
	get: return _validation
	set(value):
		if _validation == value: return
		_validation = value
		self.add_theme_stylebox_override(&"panel", ok_style_box if is_valid else error_style_box)
		refresh_tooltip()
var is_valid : bool :
	get: return validation == ""

func validate() -> void:
	validation = _get_validation()
	if self.persist and persist_load_attempted: save_persistent()
	value_changed.emit(value)
func _get_validation() -> String : return ""

func refresh_tooltip() -> void:
	self.tooltip_text = normal_tooltip if is_valid else "ERROR: %s\n%s" % [validation, normal_tooltip]


@export var ok_style_box : StyleBox
@export var error_style_box : StyleBox

@export var program : Program

## If enabled, this value will be saved to a configuration file and loaded whenever a parameter of the same node name appears.
@export var persist : bool :
	get: return $hbox/persist/check.button_pressed if find_child("check") else false
	set(value):
		if not find_child("check"): return
		$hbox/persist/check.button_pressed = value
		$hbox/persist/check.visible = not value or persist
		refresh_persist()
func refresh_persist() -> void:
	if Engine.is_editor_hint(): return
	if self.persist:
		if persist_load_attempted:
			save_persistent()
	else:
		clear_persistent()


@export var persist_disabled : bool :
	get: return $hbox/persist/check.disabled if find_child("check") else false
	set(value):
		if not find_child("check"): return
		$hbox/persist/check.disabled = value
		$hbox/persist/check.visible = not value or persist


var section_name : StringName :
	get: return program.identifier if program else &"all"

@export_tool_button("Clear Persistent") var clear_persistent_ := clear_persistent

@export_tool_button("Clear Persistent (All)") var clear_all_persistent_data := func() -> void:
	CONFIG = ConfigFile.new()
	CONFIG.save(CONFIG_PATH)

var value : Variant :
	get: return get(&"_value")
	set(val):
		set(&"_value", val)
		validate()
func set_value(val: Variant) -> void:
	value = val

var value_as_config_data : Variant :
	get: return value

var value_as_python_argument : String :
	get:
		if value is float and fmod(value, 1.0) == 0.0:
			return str(int(value))
		return str(value)


func _ready() -> void:
	if Engine.is_editor_hint(): return
	load_persistent()
	validate()


var persist_load_attempted = false
func load_persistent() -> void:
	var persist_data_exists := CONFIG.has_section_key(section_name, self.name)
	persist = persist or persist_data_exists
	if persist and persist_data_exists: value = CONFIG.get_value(section_name, self.name)
	await get_tree().create_timer(0.1).timeout
	persist_load_attempted = true


func save_persistent() -> void:
	CONFIG.set_value(section_name, self.name, self.value_as_config_data)
	CONFIG.save(CONFIG_PATH)


func clear_persistent() -> void:
	if not CONFIG.has_section_key(section_name, self.name): return
	CONFIG.erase_section_key(section_name, self.name)
	CONFIG.save(CONFIG_PATH)
