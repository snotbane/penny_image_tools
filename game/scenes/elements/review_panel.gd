class_name ReviewTree extends Tree

enum {
	BUTTONS,
	FILE,
}

enum {
	REJECT,
	OPEN,
	ACCEPT,
}

@export var target_parameter : ParameterFilepath
@export var filter_parameter : ParameterString

@export var new_preview : ImagePreview
@export var old_preview : ImagePreview

var root : TreeItem
var review_paths : PackedStringArray
var item_paths : Dictionary


func _ready() -> void:
	self.set_column_expand(BUTTONS, false)
	refresh_files.call_deferred()


func refresh_files() -> void:
	review_paths = get_files(target_parameter.value)
	refresh_items()


func refresh_items() -> void:
	self.clear()
	item_paths.clear()
	root = self.create_item()
	for i in review_paths:
		add_path_item(i)


func add_path_item(path: String):
	var result := self.create_item(root)
	item_paths[result] = path

	result.add_button(BUTTONS, preload("res://game/icons/ImportFail.svg"), REJECT)
	result.set_button_tooltip_text(BUTTONS, REJECT, "Revert Changes")
	result.add_button(BUTTONS, TaskQueue.OPEN_ICON, OPEN)
	result.set_button_tooltip_text(BUTTONS, OPEN, "Manual Review")
	result.add_button(BUTTONS, preload("res://game/icons/ImportCheck.svg"), ACCEPT)
	result.set_button_tooltip_text(BUTTONS, ACCEPT, "Accept Changes")

	result.set_text(FILE, path.substr(path.rfind("/") + 1))
	result.set_tooltip_text(FILE, path)


func open_item(item: TreeItem) -> void:
	OS.shell_open(item_paths[item])
	OS.shell_open(get_temp_path(item_paths[item]))


func accept_item(item: TreeItem) -> void:
	DirAccess.remove_absolute(get_temp_path(item_paths[item]))
	remove_path_by_item(item)
	refresh_items()
	if item == get_selected():
		old_preview.clear()


func reject_item(item: TreeItem) -> void:
	DirAccess.remove_absolute(item_paths[item])
	DirAccess.rename_absolute(get_temp_path(item_paths[item]), item_paths[item])
	remove_path_by_item(item)
	refresh_items()
	if item == get_selected():
		old_preview.value = new_preview.value
		new_preview.clear()


func remove_path_by_item(item: TreeItem) -> void:
	var path : String = item_paths[item]
	item_paths.erase(item)
	for i in review_paths.size():
		if review_paths[i] != path: continue
		review_paths.remove_at(i); break


func accept_all() -> void:
	for item in item_paths.keys():
		DirAccess.remove_absolute(get_temp_path(item_paths[item]))
	refresh_files()
	old_preview.clear()


func reject_all() -> void:
	for item in item_paths.keys():
		DirAccess.remove_absolute(item_paths[item])
		DirAccess.rename_absolute(get_temp_path(item_paths[item]), item_paths[item])
	refresh_files()
	old_preview.value = new_preview.value
	new_preview.clear()


func _on_button_clicked(item:TreeItem, column:int, id:int, mouse_button_index:int) -> void:
	set_selected(item, FILE)
	match id:
		OPEN: open_item(item)
		ACCEPT: accept_item(item)
		REJECT: reject_item(item)


func _on_item_selected() -> void:
	var selected := get_selected()
	if not selected: return
	old_preview.value = get_temp_path(item_paths[selected])
	new_preview.value = item_paths[selected]


func get_files(path: String) -> PackedStringArray:
	if DirAccess.dir_exists_absolute(path):
		return get_all_matching_files(path, RegEx.create_from_string(filter_parameter.value))
	elif FileAccess.file_exists(path):
		if RegEx.create_from_string(filter_parameter.value).search(path) and FileAccess.file_exists(get_temp_path(path)):
			return [ path ]
	return []


static func get_all_matching_files(path: String, regex: RegEx) -> PackedStringArray:
	var result : PackedStringArray = []
	var dir := DirAccess.open(path)
	if not dir.dir_exists(path): return result

	dir.list_dir_begin()
	var file := dir.get_next()
	while file:
		var full_path := path.path_join(file)
		if dir.current_is_dir():
			result.append_array(get_all_matching_files(full_path, regex))
		else:
			if regex.search(file) and FileAccess.file_exists(get_temp_path(full_path)):
				result.push_back(full_path)
		file = dir.get_next()
	dir.list_dir_end()

	return result


static func get_temp_path(file: String) -> String:
	var split := file.rfind(".")
	return file.substr(0, split) + "__" + file.substr(split)

