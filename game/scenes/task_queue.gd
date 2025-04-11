@tool class_name TaskQueue extends Tree

enum {
	BUTTONS,
	PROGRAM,
	STATUS,
	PROGRESS,
	TARGET,
	REMOVE
}

enum {
	MOVE_UP,
	MOVE_DOWN,
	COPY,
	OPEN,
	EXECUTE,
}

const MOVE_UP_ICON : Texture2D = preload("res://game/icons/MoveUp.svg")
const MOVE_DOWN_ICON : Texture2D = preload("res://game/icons/MoveDown.svg")
const COPY_ICON : Texture2D = preload("res://game/icons/ActionCopy.svg")
const OPEN_ICON : Texture2D = preload("res://game/icons/ExternalLink.svg")
const REMOVE_ICON : Texture2D = preload("res://game/icons/Remove.svg")
const STATUS_TEXTS : PackedStringArray = [ "Queued", "Running", "Completed" ]

static var inst


signal started
signal stop_requested
signal stopped


@export var run_button : Button


var _is_running : bool
var is_running : bool :
	get: return _is_running
	set(value):
		if _is_running == value: return
		_is_running = value

		run_button.text = "Stop" if _is_running else "Run"
		run_button.icon = Program.STOP_ICON if _is_running else Program.PLAY_ICON

var root : TreeItem
var tasks : Array[Task]
var task_items : Dictionary
var buttons : Dictionary


func _ready() -> void:
	inst = self

	for i in self.columns:
		self.set_column_title_alignment(i, HORIZONTAL_ALIGNMENT_LEFT)

	self.set_column_expand(BUTTONS, false)
	self.set_column_expand(REMOVE, false)
	self.set_column_expand_ratio(TARGET, 6)

	self.set_column_title(PROGRAM, "Program")
	self.set_column_title(STATUS, "Status")
	self.set_column_title(PROGRESS, "Progress")
	self.set_column_title(TARGET, "Target")

	refresh_items()


func _process(delta: float) -> void:
	for task in tasks:
		if not (task.program and task.program.is_running): continue
		refresh_task_progress(task)


func save(json_path: String) -> void:
	var json_file := FileAccess.open(json_path, FileAccess.WRITE)
	var task_data : Array = []
	for task in tasks:
		task_data.push_back(task.get_json_data())
	json_file.store_string(JSON.stringify(task_data))


func load(json_path: String) -> void:
	tasks.clear()
	var json_file := FileAccess.open(json_path, FileAccess.READ)
	var json_data : Array = JSON.parse_string(json_file.get_as_text())
	for i in json_data:
		var task := Task.new()
		task.populate_from_json(i)
		self.add(task)
	refresh_items()


func clear_all_tasks() -> void:
	tasks.clear()
	refresh_items()


func reset_completed_tasks() -> void:
	for task in tasks:
		if task.status != Task.Status.COMPLETE: continue
		task.reset()


func start_queue() -> void:
	if is_running: return
	is_running = true
	started.emit()
	for task in tasks:
		if not is_running: break
		await task.run(self.get_tree(), true)
	is_running = false
	stopped.emit()


func stop_queue():
	if not is_running: return
	is_running = false
	for task in tasks:
		if not (task.program and task.program.is_running): continue
		task.stop(true)
	stopped.emit()


func refresh_items() -> void:
	self.clear()
	task_items.clear()
	root = self.create_item()
	for i in tasks:
		add_task_item(i)


func refresh_task_status(task: Task) -> void:
	var item : TreeItem = task_items[task]
	item.set_text(STATUS, STATUS_TEXTS[task.status])

	var icon : Texture2D
	match task.status:
		1: icon = Program.STOP_ICON
		2: icon = Program.RESET_ICON
		_: icon = Program.PLAY_ICON
	item.set_button(BUTTONS, EXECUTE, icon)

	for i in self.columns:
		match i:
			BUTTONS, REMOVE: continue
		match task.status:
			2:
				item.set_custom_color(i, Color.DIM_GRAY)
				item.clear_custom_bg_color(i)
			1:
				item.set_custom_color(i, Color.WHITE)
				item.set_custom_bg_color(i, Color.SEA_GREEN)
			_:
				item.clear_custom_color(i)
				item.clear_custom_bg_color(i)

	refresh_task_progress(task)


func refresh_task_progress(task: Task) -> void:
	var item : TreeItem = task_items[task]
	if task.status == 0:
		item.set_text(PROGRESS, "")
	else:
		var progress := floori(task.progress * 100.0)
		item.set_text(PROGRESS, "%s%%" % progress)


func refresh_task_target(task: Task) -> void:
	var item : TreeItem = task_items[task]
	item.set_text(TARGET, task.target)


func find_task(item: TreeItem) -> Task:
	for i in tasks: if task_items[i] == item: return i
	return null


func add(task: Task) -> TreeItem:
	tasks.push_back(task)
	task.status_changed.connect(refresh_task_status.bind(task))
	task.parameters_changed.connect(refresh_task_target.bind(task))
	return add_task_item(task)

func add_task_item(task: Task) -> TreeItem:
	var result := self.create_item(root)
	task_items[task] = result

	for i in self.columns:
		result.set_selectable(i, false)

	result.add_button(BUTTONS, MOVE_UP_ICON, MOVE_UP)
	result.add_button(BUTTONS, MOVE_DOWN_ICON, MOVE_DOWN)
	result.add_button(BUTTONS, COPY_ICON, COPY)
	result.add_button(BUTTONS, OPEN_ICON, OPEN)
	result.add_button(BUTTONS, Program.PLAY_ICON, EXECUTE)
	result.add_button(REMOVE, REMOVE_ICON)

	result.set_text(PROGRAM, task.program_task_name)
	refresh_task_target(task)
	refresh_task_status(task)

	return result


func remove_task(task: Task) -> void:
	if task.program:
		if task.program.is_running: return
		task.program.on_close_requested()
	tasks.erase(task)
	refresh_items()
func remove_item(item: TreeItem) -> void:
	remove_task(find_task(item))


func reorder_task(task: Task, amount: int) -> void:
	var idx := tasks.find(task)
	tasks.remove_at(idx)
	idx = clamp(idx + amount, 0, tasks.size())
	tasks.insert(idx, task)

	refresh_items()
func reorder_item(item: TreeItem, amount: int) -> void:
	reorder_task(find_task(item), amount)


func copy_task(task: Task) -> void:
	var copy := task.duplicate()
	self.add(copy)
func copy_item(item: TreeItem) -> void:
	copy_task(find_task(item))


func open_task(task: Task) -> void:
	task.open(self.get_tree())
func open_item(item: TreeItem) -> void:
	open_task(find_task(item))


func execute_task(task: Task) -> void:
	match task.status:
		0:
			await task.run(self.get_tree())
			task.program.on_close_requested()
		1:
			await task.stop(true)
			task.program.on_close_requested()
		2:
			task.reset()
func execute_item(item: TreeItem) -> void:
	execute_task(find_task(item))


func _on_button_clicked(item:TreeItem, column:int, id:int, mouse_button_index:int) -> void:
	match column:
		BUTTONS:
			match id:
				MOVE_UP: reorder_item(item, -1)
				MOVE_DOWN: reorder_item(item, +1)
				COPY: copy_item(item)
				OPEN: open_item(item)
				EXECUTE: execute_item(item)
		REMOVE: remove_item(item)


func _on_queue_run_pressed() -> void:
	if is_running: stop_queue()
	else: start_queue()
