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
	MOVE_UP_BUTTON,
	MOVE_DOWN_BUTTON,
	OPEN_BUTTON,
	EXECUTE_BUTTON,
}

const MOVE_UP_ICON : Texture2D = preload("res://game/icons/MoveUp.svg")
const MOVE_DOWN_ICON : Texture2D = preload("res://game/icons/MoveDown.svg")
const OPEN_ICON : Texture2D = preload("res://game/icons/ExternalLink.svg")
const REMOVE_ICON : Texture2D = preload("res://game/icons/Remove.svg")
const START_ICON : Texture2D = preload("res://game/icons/Play.svg")
const STOP_ICON : Texture2D = preload("res://game/icons/Stop.svg")
const RESET_ICON : Texture2D = preload("res://game/icons/Reload.svg")
const STATUS_TEXTS : PackedStringArray = [ "Queued", "Running", "Completed" ]


static var inst


signal started
signal stop_requested
signal stopped


var is_running : bool
var running_tasks : Array[Task]
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
	if is_running:
		for task in running_tasks:
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
		tasks.push_back(task)
	refresh_items()


func start_queue() -> void:
	if is_running: return
	is_running = true
	started.emit()
	for task in tasks:
		await task.run_in_queue(self.get_tree())
	is_running = false
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
	item.set_button(BUTTONS, EXECUTE_BUTTON, STOP_ICON if task.status == 1 else START_ICON)


func refresh_task_progress(task: Task) -> void:
	var item : TreeItem = task_items[task]
	var progress_100 : int
	match task.status:
		1: progress_100 = floori(task.progress * 100)
		2: progress_100 = 100
		_: progress_100 = 0
	item.set_text(PROGRESS, "%s%%" % progress_100)


func find_task(item: TreeItem) -> Task:
	for i in tasks: if task_items[i] == item: return i
	return null


func add(task: Task) -> TreeItem:
	tasks.push_back(task)
	task.status_changed.connect(refresh_task_status.bind(task))
	return add_task_item(task)

func add_task_item(task: Task) -> TreeItem:
	var result := self.create_item(root)
	task_items[task] = result

	result.add_button(BUTTONS, MOVE_UP_ICON, MOVE_UP_BUTTON)
	result.add_button(BUTTONS, MOVE_DOWN_ICON, MOVE_DOWN_BUTTON)
	result.add_button(BUTTONS, OPEN_ICON, OPEN_BUTTON)
	result.add_button(BUTTONS, START_ICON, EXECUTE_BUTTON)
	result.add_button(REMOVE, REMOVE_ICON)

	result.set_text(PROGRAM, task.program_task_name)
	result.set_text(TARGET, task.target)
	refresh_task_status(task)
	refresh_task_progress(task)

	return result


func remove_task(task: Task) -> void:
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


func open_task(task: Task) -> void:
	task.create_window(self.get_tree())
func open_item(item: TreeItem) -> void:
	open_task(find_task(item))


func _on_button_clicked(item:TreeItem, column:int, id:int, mouse_button_index:int) -> void:
	match column:
		BUTTONS:
			match id:
				MOVE_UP_BUTTON: reorder_item(item, -1)
				MOVE_DOWN_BUTTON: reorder_item(item, +1)
				OPEN_BUTTON: open_item(item)
				EXECUTE_BUTTON: find_task(item).run_manually(self.get_tree())
		REMOVE: remove_item(item)
