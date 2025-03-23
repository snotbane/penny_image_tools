class_name SettingsPanel extends PanelContainer

const CONFIG_PATH := "user://prefs.cfg"

static var inst : SettingsPanel

@export var optipng_path_param : ParameterString
static var optipng_path : String :
	get: return inst.optipng_path_param.text

var config : ConfigFile

func _ready() -> void:
	inst = self
	config = ConfigFile.new()

	var err := config.load(CONFIG_PATH)
	if err != OK: return

	# optipng_path_param.text = config.get_value("all", "optipng_path", "")


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_WM_CLOSE_REQUEST, NOTIFICATION_CRASH:
			_exit_tree()

func _exit_tree() -> void:
	# config.set_value("all", "optipng_path", optipng_path_param.to_string())

	# config.save(CONFIG_PATH)
	print("Saved to ", ProjectSettings.globalize_path(CONFIG_PATH))
