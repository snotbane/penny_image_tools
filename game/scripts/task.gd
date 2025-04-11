class_name Task extends Resource

signal status_changed

const PROGRAMS_BY_IDENTIFIER : Dictionary = {
	&"dummy":		preload("res://game/scenes/programs/program_dummy.tscn"),
	&"optipng":		preload("res://game/scenes/programs/program_optipng.tscn"),
	&"laigter":		preload("res://game/scenes/programs/program_laigter.tscn"),
	&"fatlas":		preload("res://game/scenes/programs/program_fatlas.tscn"),
}
const PROGRAM_TASK_NAMES : Dictionary = {
	&"dummy":		"Dummy",
	&"optipng":		"OptiPNG",
	&"laigter":		"Laigter",
	&"fatlas":		"Fatlas",
}
const WINDOW_SCENE : PackedScene = preload("res://game/scenes/program_window.tscn")


var identifier : StringName
var data : Dictionary
var program : Program
var target : String
var status : int


var program_scene : PackedScene :
	get: return PROGRAMS_BY_IDENTIFIER[identifier]

var program_task_name : String :
	get: return PROGRAM_TASK_NAMES[identifier]

var progress : float :
	get: return program.get_progress()




func populate_from_program(_program: Program) -> void:
	program = _program
	identifier = program.identifier
	data = program.save_parameters()
	target = program.target_parameter.value if program.target_parameter else ""


func run_manually(tree: SceneTree) -> void:
	create_window(tree, Parameter.get_persistent_parameter(&"queue_privacy", 0) > 0)
	program.start.call_deferred()


func run_in_queue(tree: SceneTree):
	create_window(tree, Parameter.get_persistent_parameter(&"queue_privacy", 0) > 0)
	program.start.call_deferred()
	await program.stopped


func stop() -> void:
	program.stop()


func create_window(tree: SceneTree, show: bool = true) -> ProgramWindow:
	var result : ProgramWindow = WINDOW_SCENE.instantiate()
	result.hide()
	result.populate(program_scene, show)
	result.force_native = true
	tree.root.add_child.call_deferred(result)

	program = result.program
	program.load_parameters(data)

	return result
