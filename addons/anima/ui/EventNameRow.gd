tool
extends MarginContainer

signal delete_event(index)

var _default_name: String
var _index: int

func set_label(name: String) -> void:
	$HBoxContainer/Label.text = name

func set_index(index: int) -> void:
	_index = index

func _on_DeleteButton_pressed():
	emit_signal("delete_event", _index)

	queue_free()
