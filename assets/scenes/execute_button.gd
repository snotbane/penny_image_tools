extends Button

signal executed
signal canceled

var _is_executing : bool
@export var is_executing : bool :
	get: return _is_executing
	set(value):
		if _is_executing == value: return
		_is_executing = value

		self.button_pressed = _is_executing
		self.text = "Cancel" if _is_executing else "Execute"
		if _is_executing:
			executed.emit()
		else:
			canceled.emit()
		# (executed if _is_executing else canceled).emit()


func _ready() -> void:
	self.text = "Cancel" if is_executing else "Execute"


func _on_toggled(toggled_on:bool) -> void:
	is_executing = toggled_on
