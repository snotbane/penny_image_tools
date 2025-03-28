extends NativeProgram

@export var param_optipng_path : ParameterFilepath
@export var param_source_path : ParameterFilepath

@export var source_preview : ImagePreview
@export var progress_display : ProgressDisplay
@export var bytes_display : Control

func _program(args: Array) -> Variant:
	var arg_optipng_path : String = args[0]
	var arg_source_path : String = args[1]

	var compress_image = func(source: String, i: int) -> void:
		source_preview.set.call_deferred(&"image_path", source)
		progress_display.set.call_deferred(&"value", i)

		var file := FileAccess.open(source, FileAccess.READ)
		var bytes_before := file.get_length()

		var output = []
		var err := OS.execute(arg_optipng_path, ["-o7", "-out", source, source], output, print_output)
		if print_output: for s in output: print(s)
		if err != OK:
			printerr("Error compressing image at path '%s'" % source)
			return

		var bytes_after := file.get_length()
		bytes_display.add_bytes_reduced.call_deferred(bytes_before - bytes_after)

	if DirAccess.dir_exists_absolute(arg_source_path):
		var aggregate_files := func(path: String, arg: PackedStringArray) -> PackedStringArray:
			if path.to_lower().ends_with(".png"):
				arg.push_back(path)
			return arg

		bytes_display.clear_bytes_reduced.call_deferred()
		var paths : PackedStringArray = foreach_file_in_dir(arg_source_path, aggregate_files, [])
		progress_display.set.call_deferred(&"max_value", paths.size())
		foreach_file(paths, compress_image)
		progress_display.set.call_deferred(&"value", paths.size())
	elif FileAccess.file_exists(arg_source_path):
		progress_display.set.call_deferred(&"max_value", 1)
		compress_image.call(arg_source_path, 0)
		progress_display.set.call_deferred(&"value", 1)
	else:
		printerr("Input path '%s' is not a valid file nor directory." % arg_source_path)
		return 1
	return 0


func foreach_file(paths: PackedStringArray, method: Callable, idx: int = 0) -> void:
	for i in paths.size():
		if not is_executing: break
		method.call(paths[i], i)


func foreach_file_in_dir(path: String, method: Callable, arg: Variant = null) -> Variant:
	var dir := DirAccess.open(path)
	if not dir: return arg
	dir.list_dir_begin()
	var file := dir.get_next()
	while file:
		if not is_executing: break
		var full := path + "/" + file
		# prints(full, file)
		if dir.current_is_dir():
			arg = foreach_file_in_dir(full, method, arg)
		else:
			arg = method.call(full, arg)
		file = dir.get_next()
	return arg


static func is_process_running(pid: int) -> bool:
	var output = []
	var code := OS.execute("kill", ["-0", str(pid)], output, true)
	prints(code, output)
	return code == 0
