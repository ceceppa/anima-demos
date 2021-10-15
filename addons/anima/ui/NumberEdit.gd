tool
extends LineEdit

enum Type {
	INTEGER,
	FLOAT,
}

const REG_EX = {
	Type.INTEGER: "^[0-9]*$",
	Type.FLOAT: "^([0-9]*[.])?[0-9]+",
}

export (Type) var type

var _regex = RegEx.new()
var _old_text: String

func _ready():
	var regex: String = REG_EX[type]

	print(regex)

	_regex.compile(regex)

func _on_NumberEdit_text_changed(new_text):
	if _regex.search(new_text):
		_old_text = new_text
	else:
		text = _old_text

	set_cursor_position(text.length())

func get_value():
	if type == Type.INTEGER:
		return int(text)
	else:
		return float(text)
