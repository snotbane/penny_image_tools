@tool class_name Parameter extends Control

const CONFIG_PATH := "user://prefs.cfg"
static var CONFIG := ConfigFile.new()

static func _static_init() -> void:
	var err := CONFIG.load(CONFIG_PATH)
	if err != OK:
		CONFIG.save(CONFIG_PATH)


static func get_global(section: StringName, key: StringName, default: Variant = null) -> Variant:
	return CONFIG.get_value(section, key, default)


static func set_global(section: StringName, key: StringName, val: Variant) -> void:
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
	value_changed.emit(value)
	if persist: save_persistent()
func _get_validation() -> String : return ""

func refresh_tooltip() -> void:
	self.tooltip_text = normal_tooltip if is_valid else "ERROR: %s\n%s" % [validation, normal_tooltip]


@export var ok_style_box : StyleBox
@export var error_style_box : StyleBox

@export var program : Program


@export var persist : bool :
	get: return $hbox/persist/check.button_pressed if find_child("check") else false
	set(val):
		if not find_child("check"): return
		$hbox/persist/check.button_pressed = val
		$hbox/persist/check.visible = val or not persist_disabled
		refresh_persist()
func refresh_persist() -> void:
	if Engine.is_editor_hint(): return
	if self.persist:
		save_persistent()
	else:
		clear_persistent()


@export var persist_disabled : bool :
	get: return $hbox/persist/check.disabled if find_child("check") else false
	set(val):
		if not find_child("check"): return
		$hbox/persist/check.disabled = val
		$hbox/persist/check.visible = not val or persist


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


var value_as_python_argument : String :
	get:
		if value is float and fmod(value, 1.0) == 0.0:
			return str(int(value))
		return str(value)


func _ready() -> void:
	if Engine.is_editor_hint(): return
	load_persistent()
	validate()


func load_persistent() -> void:
	var already_persistent := persist
	var will_be_persistent := CONFIG.has_section_key(section_name, self.name)
	$hbox/persist/check.button_pressed = will_be_persistent or already_persistent
	$hbox/persist/check.visible = $hbox/persist/check.button_pressed or not persist_disabled
	if will_be_persistent:
		set(&"_value", CONFIG.get_value(section_name, self.name, self.value))
		validate()
	elif already_persistent:
		save_persistent()


func save_persistent() -> void:
	CONFIG.set_value(section_name, self.name, self.value)
	CONFIG.save(CONFIG_PATH)


func clear_persistent() -> void:
	if not CONFIG.has_section_key(section_name, self.name): return
	CONFIG.erase_section_key(section_name, self.name)
	CONFIG.save(CONFIG_PATH)
