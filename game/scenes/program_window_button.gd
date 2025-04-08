extends Button

const window_scene : PackedScene = preload("res://game/scenes/program_window.tscn")


@export_file("*.tscn", "*.scn", "*.res") var scene_path : String
var scene : PackedScene :
	get: return load(scene_path)


func _pressed() -> void:
	var window : ProgramWindow = window_scene.instantiate()
	window.hide()
	window.force_native = true
	window.populate(scene)
	self.get_tree().root.add_child.call_deferred(window)
