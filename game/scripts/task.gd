class_name Task extends Resource

enum Status {
	QUEUED,
	RUNNING,
	COMPLETE,
	FAILED,
}

signal status_changed
signal parameters_changed

const PROGRAMS_BY_IDENTIFIER : Dictionary = {
	&"dummy":		preload("res://game/scenes/programs/program_dummy.tscn"),
	&"optipng":		preload("res://game/scenes/programs/program_optipng.tscn"),
	&"laigter":		preload("res://game/scenes/programs/program_laigter.tscn"),
	&"fatlas":		preload("res://game/scenes/programs/program_fatlas.tscn"),
	&"cleanup":		preload("res://game/scenes/programs/program_cleanup.tscn"),
}
const PROGRAM_TASK_NAMES : Dictionary = {
	&"dummy":		"Dummy",
	&"optipng":		"OptiPNG",
	&"laigter":		"Laigter",
	&"fatlas":		"Fatlas",
	&"cleanup":		"Cleanup",
}
const WINDOW_SCENE : PackedScene = preload("res://game/scenes/program_window.tscn")


@export var identifier : StringName
@export var parameters : Dictionary
@export var target : String

var program : Program

var _status : int
var status : int :
	get: return _status
	set(value):
		if _status == value: return
		_status = value
		status_changed.emit()


var program_scene : PackedScene :
	get: return PROGRAMS_BY_IDENTIFIER[identifier]

var program_task_name : String :
	get: return PROGRAM_TASK_NAMES[identifier]


var progress : float :
	get: return program.progress_display.progress_percent if program and program.progress_display else -1.0


func get_json_data() -> Dictionary:
	return {
		&"identifier":	identifier,
		&"parameters":	parameters,
	}


func _init(_identifier: StringName = &"program") -> void:
	identifier = _identifier


func populate_from_json(json: Dictionary) -> void:
	identifier = json[&"identifier"]
	parameters = json[&"parameters"]
	target = parameters.get(&"target", "")


func populate_from_program(_program: Program) -> void:
	program = _program
	identifier = program.identifier
	refresh_parameters()


func refresh_parameters() -> void:
	parameters = program.save_parameters()
	target = program.target_parameter.value if program.target_parameter else ""
	parameters_changed.emit()


func open(tree: SceneTree, show: bool = true) -> ProgramWindow:
	if program:
		if show:
			program.window.show()
			program.window.grab_focus()
		return program.window
	else:
		var result : ProgramWindow = WINDOW_SCENE.instantiate()
		result.hide()
		# result.force_native = true
		result.populate(program_scene, show)
		tree.root.add_child.call_deferred(result)

		result.hidden.connect(refresh_parameters)

		program = result.program
		program.started.connect(set.bind(&"status", Status.RUNNING))
		program.succeeded.connect(set.bind(&"status", Status.COMPLETE))
		program.failed.connect(set.bind(&"status", Status.FAILED))
		if parameters:
			if Parameter.get_persistent_parameter(&"all", &"persist_overrides_task", true):
				program.load_parameters(parameters)
			else:
				program.load_parameters.call_deferred(parameters)

		return result


func run(tree: SceneTree, close_after_stopped: bool = false):
	self.open(tree, Parameter.get_persistent_parameter(&"all", &"queue_privacy", 0) > 0)
	program.start.call_deferred()
	await program.stopped
	if close_after_stopped: program.on_close_requested()


func stop(_reset: bool = false):
	program.stop()
	await program.stopped
	if _reset: reset()


func reset() -> void:
	status = Status.QUEUED
