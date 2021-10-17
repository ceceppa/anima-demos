tool
extends LineEdit

signal changed

enum Type {
	INTEGER,
	FLOAT,
}

const REG_EX = {
	Type.INTEGER: "^[+-][0-9]*$",
	Type.FLOAT: "^[+-]?([0-9]+([.][0-9]*)?|[.][0-9]+)$",
}

export (Type) var type

var _regex = RegEx.new()
var _old_text: String

func _ready():
	var regex: String = REG_EX[type]

	_regex.compile(regex)

func _on_NumberEdit_text_changed(new_text: String):
	# The regex validates the -/+ sign correctly but will
	# not allow to them to be the only value in the field, but we need to accept them
	if _regex.search(new_text) or new_text == '' or ['+', '-'].find(new_text) >= 0:
		_old_text = new_text

		emit_signal("changed")
	else:
		text = _old_text

		set_cursor_position(text.length())

func get_value():
	if type == Type.INTEGER:
		return int(text)
	else:
		return float(text)
