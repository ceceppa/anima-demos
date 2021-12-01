tool
extends LineEdit

signal changed
signal type_changed(new_type)

enum Type {
	INTEGER,
	FLOAT,
	STRING
}

const REG_EX = {
	Type.INTEGER: "^[+-]?[0-9]*$",
	Type.FLOAT: "^[+-]?([0-9]*([.][0-9]*)?|[.][0-9]+)$",
	Type.STRING: ".*",
}

export (Type) var type setget set_type

var _regex := RegEx.new()

var _old_text: String

func _ready():
	var regex: String = REG_EX[type]

	_regex.compile(regex)

func _on_NumberEdit_text_changed(new_text: String):
	# The regex validates the -/+ sign correctly but will
	# not allow to them to be the only value in the field, but we need to accept them
	var is_valid = _regex.search(new_text) or \
		new_text == '' or \
		['+', '-'].find(new_text) == 0

	if is_valid:
		_old_text = new_text

		emit_signal("changed")
	else:
		text = _old_text

		set_cursor_position(text.length())

func get_value():
	if text.find(":") >= 0:
		return text

	if type == Type.INTEGER:
		return int(text)
	elif type == Type.FLOAT:
		return float(text)
	else:
		return text

func set_value(value: String) -> void:
	text = value

func set_type(new_type: int) -> void:
	type = new_type

	var regex: String = REG_EX[type]

	_regex.compile(regex)

	emit_signal("type_changed", new_type)

func get_type() -> int:
	return type
