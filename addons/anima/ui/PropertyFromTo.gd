tool
extends Control

signal vale_updated

onready var _current_value_button: Button = find_node('CurrentValue')
onready var _custom_value: HBoxContainer = find_node('CustomValue')
onready var _delete_button: Button = find_node('DeleteButton')

var _input_visible: Control

func _ready():
#	_current_value_button.show()
#	_custom_value.hide()
#
	pass

func set_type(type: int) -> void:
	var node_name: String = 'FreeText'

	for child in $CustomValue.get_children():
		if child is Button:
			continue

		child.hide()

	match type:
		TYPE_INT:
			node_name = 'Number'
		TYPE_REAL:
			node_name = 'Real'
		TYPE_VECTOR2:
			node_name = 'Vector2'
		TYPE_VECTOR3:
			node_name = 'Vector3'
		_:
			printerr('set_type: unsupported type' + str(type))

	_input_visible = find_node(node_name)
	_input_visible.show()

func _animate_custom_value(mode: int) -> void:
	var anima: AnimaNode = Anima.begin(self)
	anima.set_single_shot(true)
	anima.set_default_duration(0.3)

	anima.then({
		node = _current_value_button,
		property = "scale",
		from = Vector2(1, 1),
		to = Vector2(0.5, 0.5),
		pivot = Anima.PIVOT.CENTER,
	})
	anima.also({
		property = "opacity",
		from = 1.0,
		to = 0.0
	})
	anima.with({
		node = _custom_value,
		property = "scale",
		from = Vector2(1.5, 1.5),
		to = Vector2(1, 1),
		pivot = Anima.PIVOT.CENTER,
		easing = Anima.EASING.EASE_OUT_BACK,
		on_started = [funcref(self, '_handle_custom_value_visibility'), [true], [false]]
	})
	anima.also({
		property = "opacity",
		from = 0.0,
		to = 1.0
	})

	_custom_value.show()

	if mode == AnimaTween.PLAY_MODE.NORMAL:
		anima.play()
		
		yield(anima, "animation_completed")

		_input_visible.grab_focus()
	else:
		anima.play_backwards()

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
	_animate_custom_value(AnimaTween.PLAY_MODE.NORMAL)

func _on_DeleteButton_pressed():
	_animate_custom_value(AnimaTween.PLAY_MODE.BACKWARDS)

func _on_input_changed() -> void:
	emit_signal('vale_updated')

func _on_FreeText_text_changed(_new_text):
	emit_signal("vale_updated")

func _handle_custom_value_visibility(visible: bool) -> void:
	_custom_value.visible = visible
