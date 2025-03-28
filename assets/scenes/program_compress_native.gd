extends NativeProgram

@export var param_optipng_path : ParameterFilepath
@export var param_source_path : ParameterFilepath

@export var source_preview : ImagePreview
@export var progress_display : ProgressDisplay

func _program(args: Array) -> Variant:
	var arg_optipng_path : String = param_optipng_path.text
	var arg_source_path : String = param_source_path.text

	var compress_image = func(source: String):
		progress_display.value += 1
		pass

	progress_display.value = 0
	if DirAccess.dir_exists_absolute(arg_source_path):
		progress_display.value = foreach_file(arg_source_path, func(path, arg): return arg + 1)
		foreach_file(arg_source_path, compress_image)
	elif FileAccess.file_exists(arg_source_path):
		progress_display.max_value = 1
		compress_image.call(arg_source_path)
	else:
		printerr("Input path '%s' is not a valid file nor directory." % arg_source_path)
		return 1

	return 0


static func foreach_file(path: String, method: Callable, arg: Variant = null) -> Variant:
	var dir := DirAccess.open(path)
	if not dir: return arg
	dir.list_dir_begin()
	var file := dir.get_next()
	while file:
		var full := path + file
		if dir.current_is_dir():
			arg = foreach_file(full + "/", method, arg)
		else:
			arg = method.call(full, arg)
		file = dir.get_next()
	return arg
