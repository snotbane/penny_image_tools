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

enum {
	OLD,
	NEW,
	OLD_BITMAP,
	NEW_BITMAP,
}

@export var program : Program

@export var target_parameter : ParameterFilepath
@export var filter_include : ParameterString
@export var filter_exclude : ParameterString

@export var old_preview : ImagePreview
@export var new_preview : ImagePreview
@export var old_bitmap : ImagePreview
@export var new_bitmap : ImagePreview

var root : TreeItem
var review_paths : PackedStringArray
var item_paths : Dictionary


func _ready() -> void:
	self.set_column_expand(BUTTONS, false)
	refresh_files.call_deferred()


func clear_items() -> void:
	review_paths.clear()
	refresh_items()


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
	OS.shell_open(get_alt_path(item_paths[item], NEW))


func accept_item(item: TreeItem) -> void:
	var old := FileAccess.open(item_paths[item], FileAccess.WRITE)
	var new := FileAccess.open(get_alt_path(item_paths[item], NEW), FileAccess.READ)

	var buffer := new.get_buffer(new.get_length())
	old.store_buffer(buffer)

	remove_path_by_item(item)
	refresh_items()
	if item == get_selected():
		old_preview.clear()
		old_bitmap.clear()
		new_bitmap.clear()


func reject_item(item: TreeItem) -> void:
	remove_path_by_item(item)
	refresh_items()
	if item == get_selected():
		new_preview.clear()
		old_bitmap.clear()
		new_bitmap.clear()


func remove_path_by_item(item: TreeItem) -> void:
	var path : String = item_paths[item]
	item_paths.erase(item)
	for i in review_paths.size():
		if review_paths[i] != path: continue
		review_paths.remove_at(i); break
	DirAccess.remove_absolute(get_alt_path(path, NEW))
	DirAccess.remove_absolute(get_alt_path(path, OLD_BITMAP))
	DirAccess.remove_absolute(get_alt_path(path, NEW_BITMAP))


func accept_all() -> void:
	for item in item_paths.keys():
		var old := FileAccess.open(item_paths[item], FileAccess.WRITE)
		var new := FileAccess.open(get_alt_path(item_paths[item], NEW), FileAccess.READ)

		var buffer := new.get_buffer(new.get_length())
		old.store_buffer(buffer)

		remove_path_by_item(item)
	refresh_files()
	old_preview.clear()
	old_bitmap.clear()
	new_bitmap.clear()


func reject_all() -> void:
	for item in item_paths.keys():
		remove_path_by_item(item)
	refresh_files()
	new_preview.clear()
	old_bitmap.clear()
	new_bitmap.clear()


func open_target_directory() -> void:
	var path : String = target_parameter.value
	if DirAccess.dir_exists_absolute(path): OS.shell_open(path)
	elif FileAccess.file_exists(path): OS.shell_open(path.substr(0, path.rfind("/")))


func _on_button_clicked(item:TreeItem, column:int, id:int, mouse_button_index:int) -> void:
	set_selected(item, FILE)
	var next := clampi(item.get_index() + 1, 0, self.review_paths.size() - 1)
	match id:
		REJECT: reject_item(item); select_tree_item_by_index(next)
		OPEN: open_item(item)
		ACCEPT: accept_item(item); select_tree_item_by_index(next)



func _on_item_selected() -> void:
	var selected := get_selected()
	var path : String = item_paths[selected] if selected and item_paths.has(selected) else ""
	old_preview.value = get_alt_path(path, OLD)
	new_preview.value = get_alt_path(path, NEW)
	old_bitmap.value = get_alt_path(path, OLD_BITMAP)
	new_bitmap.value = get_alt_path(path, NEW_BITMAP)


func get_files(path: String) -> PackedStringArray:
	if DirAccess.dir_exists_absolute(path):
		return get_all_matching_files(path, RegEx.create_from_string(filter_include.value), RegEx.create_from_string(filter_exclude.value))
	elif FileAccess.file_exists(path):
		if RegEx.create_from_string(filter_include.value).search(path) and FileAccess.file_exists(get_alt_path(path, NEW)):
			return [ path ]
	return []


func get_all_matching_files(path: String, include: RegEx, exclude: RegEx) -> PackedStringArray:
	var result : PackedStringArray = []
	var dir := DirAccess.open(path)
	if not dir.dir_exists(path): return result

	dir.list_dir_begin()
	var file := dir.get_next()
	while file:
		var full_path := path.path_join(file)
		if dir.current_is_dir():
			result.append_array(get_all_matching_files(full_path, include, exclude))
		else:
			if	(include.get_pattern() == "" or include.search(file) != null) and \
				(exclude.get_pattern() == "" or exclude.search(file) == null) and \
				FileAccess.file_exists(get_alt_path(full_path, NEW)):
					result.push_back(full_path)
		file = dir.get_next()
	dir.list_dir_end()
	return result


func get_alt_path(old: String, type: int = NEW) -> String:
	if type == OLD: return old

	var file : String = old.substr(old.rfind("/") + 1)
	var split := file.rfind(".")
	var p_name := file.substr(0, split)
	var ext := file.substr(split)

	var p_root := program.temp_folder_path
	var suffix : String
	match type:
		NEW:suffix = "__new"
		OLD_BITMAP: suffix = "__old_b"
		NEW_BITMAP: suffix = "__new_b"

	return p_root.path_join(p_name + suffix + ext)


func select_tree_item_by_index(idx: int) -> void:
	if root == null:
		return

	var queue: Array = [root]
	var current_index = 0

	while queue.size() > 0:
		var item: TreeItem = queue.pop_front()
		if current_index == idx:
			self.set_selected(item, FILE)
			return
		current_index += 1

		var child = item.get_first_child()
		while child:
			queue.append(child)
			child = child.get_next()
