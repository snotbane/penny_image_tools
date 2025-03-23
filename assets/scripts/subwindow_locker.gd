extends Control

@onready var parent : Control = get_parent()

var is_locked : bool :
	get: return self.visible
	set(value):
		self.visible = value
		self.parent.modulate = Color(self.parent.modulate.r, self.parent.modulate.g, self.parent.modulate.b, 0.5 if is_locked else 1.0)


func _ready() -> void:
	is_locked = is_locked
