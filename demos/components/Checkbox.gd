tool
extends "res://demos/components/Button.gd"

export (bool) var _checked = false

func _ready():
	_set_style(Style.DEFAULT)

	_update_style()

func _update_style() -> void:
	if _checked:
		_set_style(Style.PRIMARY)
	else:
		_set_style(Style.DEFAULT)

func set_checked(checked: bool) -> void:
	_checked = checked

	_update_style()
