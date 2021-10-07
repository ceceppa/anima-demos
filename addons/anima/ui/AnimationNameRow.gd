tool
extends MarginContainer

signal delete_animation
signal play_animation

var _default_name: String

func _ready():
	$HBoxContainer/Button.icon = AnimaUI.get_godot_icon('Play')

func disable_delete_button() -> void:
	$HBoxContainer/DeleteButton.hide()
	$HBoxContainer/LineEdit.editable = false

func set_default_name(name: String) -> void:
	_default_name = name

	$HBoxContainer/LineEdit.text = name

func set_tooltip(tooltip: String) -> void:
	$HBoxContainer/LineEdit.hint_tooltip = tooltip

func _on_LineEdit_focus_exited():
	if $HBoxContainer/LineEdit.text.strip_edges() == '':
		$HBoxContainer/LineEdit.text = _default_name

func _on_DeleteButton_pressed():
	emit_signal("delete_animation")

	queue_free()

func _on_Button_pressed():
	emit_signal("play_animation")
