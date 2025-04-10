@tool class_name TaskQueue extends Tree

enum {
	MOVE_UP,
	MOVE_DOWN,
	# ID,
	PROGRAM,
	STATUS,
	DATA,
	REMOVE
}


const PROGRAM_NAME : String = "Program"
const STATUS_NAME : String = "Status"
const DATA_NAME : String = "Data"
const MOVE_UP_ICON : Texture2D = preload("res://game/icons/MoveUp.svg")
const MOVE_DOWN_ICON : Texture2D = preload("res://game/icons/MoveDown.svg")
const REMOVE_ICON : Texture2D = preload("res://game/icons/Remove.svg")
const STATUS_TEXTS : PackedStringArray = [ "Queued", "Running", "Completed" ]


var root : TreeItem

var tasks : Array[Task]

var task_items : Dictionary
var buttons : Dictionary


func _ready() -> void:
	self.set_column_expand(MOVE_UP, false)
	self.set_column_expand(MOVE_DOWN, false)
	self.set_column_expand(REMOVE, false)

	self.set_column_expand_ratio(DATA, 6)

	self.set_column_title(PROGRAM, PROGRAM_NAME)
	self.set_column_title(STATUS, STATUS_NAME)
	self.set_column_title(DATA, DATA_NAME)
	for i in self.columns:
		self.set_column_title_alignment(i, HORIZONTAL_ALIGNMENT_LEFT)

	refresh_items()

	add(Task.new(str(0)))
	add(Task.new(str(1)))
	add(Task.new(str(2)))


func refresh_items() -> void:
	self.clear()
	task_items.clear()
	root = self.create_item()
	for i in tasks:
		add_task_item(i)



func find_task(item: TreeItem) -> Task:
	for i in tasks: if task_items[i] == item: return i
	return null


func add(task: Task) -> TreeItem:
	tasks.push_back(task)
	return add_task_item(task)

func add_task_item(task: Task) -> TreeItem:
	var result := self.create_item(root)

	result.set_text(PROGRAM, "Type")
	result.set_text(DATA, task.data)
	result.set_text(STATUS, "Queued")

	result.add_button(MOVE_UP, MOVE_UP_ICON)
	result.add_button(MOVE_DOWN, MOVE_DOWN_ICON)
	result.add_button(REMOVE, REMOVE_ICON)

	task_items[task] = result
	return result



func set_status(item: TreeItem, status: int) -> void:
	status = clamp(status, 0, STATUS_TEXTS.size() - 1)
	item.set_text(STATUS, STATUS_TEXTS[status])


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


func _on_button_clicked(item:TreeItem, column:int, id:int, mouse_button_index:int) -> void:
	match column:
		MOVE_UP: reorder_item(item, -1)
		MOVE_DOWN: reorder_item(item, +1)
		REMOVE: remove_item(item)
