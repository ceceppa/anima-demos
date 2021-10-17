tool
extends HBoxContainer

signal vale_updated

onready var _current_value_button: Button = find_node('CurrentValue')
onready var _custom_value: HBoxContainer = find_node('CustomValue')
onready var _delete_button: Button = find_node('DeleteButton')

var _input_visible: Control

func _ready():
	_current_value_button.show()
	_custom_value.hide()

func set_type(type: int) -> void:
	for child in $CustomValue.get_children():
		if child is Button:
			continue

		child.hide()

	match type:
		TYPE_INT:
			_input_visible = $CustomValue/Number
		TYPE_REAL:
			_input_visible = $CustomValue/Real
		TYPE_VECTOR2:
			_input_visible = $CustomValue/Vector2
		TYPE_VECTOR3:
			_input_visible = $CustomValue/Vector3
		_:
			printerr('set_type: unsupported type' + str(type))
			_input_visible = $CustomValue/FreeText

	_input_visible.show()

func set_value(value) -> void:
	if _input_visible is LineEdit:
		_input_visible.text = str(value)
	elif _input_visible.name == 'Vector2':
		var x: LineEdit = _input_visible.find_node('x')
		var y: LineEdit = _input_visible.find_node('y')

		x.text = str(value[0])
		y.text = str(value[1])
	elif _input_visible.name == 'Vector3':
		var x: LineEdit = _input_visible.find_node('x')
		var y: LineEdit = _input_visible.find_node('y')
		var z: LineEdit = _input_visible.find_node('z')

		x.text = str(value[0])
		y.text = str(value[1])
		z.text = str(value[2])

	_on_CurrentValue_pressed()

func get_value():
	if _input_visible is LineEdit:
		return _input_visible.get_value()
	elif _input_visible.name == 'Vector2':
		var x: LineEdit = _input_visible.find_node('x')
		var y: LineEdit = _input_visible.find_node('y')

		return [x, y]
	elif _input_visible.name == 'Vector3':
		var x: LineEdit = _input_visible.find_node('x')
		var y: LineEdit = _input_visible.find_node('y')
		var z: LineEdit = _input_visible.find_node('z')

		return [x, y, z]

func _on_CurrentValue_pressed():
	_current_value_button.hide()
	_custom_value.show()

	_input_visible.grab_focus()

func _on_DeleteButton_pressed():
	_current_value_button.show()
	_custom_value.hide()

func _on_input_changed() -> void:
	emit_signal('vale_updated')

func _on_FreeText_text_changed(_new_text):
	emit_signal("vale_updated")
