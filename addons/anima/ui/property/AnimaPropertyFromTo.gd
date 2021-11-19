tool
extends Control

signal vale_updated

enum TYPES {
	INT = TYPE_INT,
	REAL = TYPE_REAL,
	VECTOR2 = TYPE_VECTOR2,
	VECTOR3 = TYPE_VECTOR3,
	STRING = TYPE_STRING
}

onready var _current_value_button: Button = find_node('CurrentValue')
onready var _custom_value: HBoxContainer = find_node('CustomValue')
onready var _delete_button: Button = find_node('DeleteButton')

export (String) var label = 'current value' setget set_label
export (TYPES) var type = TYPES.INT setget set_type
export (bool) var can_clear_custom_value := true setget set_can_clear_custom_value
export (bool) var show_relative_button := true setget set_show_relative_button

var _input_visible: Control

func _ready():
	if _input_visible == null:
		_on_ClearButton_pressed()

func set_type(the_type: int) -> void:
	type = the_type
	var node_name: String = 'FreeText'
	var custom_value = find_node('CustomValue')

	if custom_value == null:
		return

	for child in custom_value.get_children():
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
		TYPE_STRING:
			node_name = 'FreeText'
		_:
			printerr('set_type: unsupported type' + str(type))

	node_name = 'Carousel'
	_input_visible = find_node(node_name)
	_input_visible.show()

func set_can_clear_custom_value(can_clear: bool) -> void:
	can_clear_custom_value = can_clear

	var clear_button = find_node('ClearButton')
	clear_button.visible = can_clear_custom_value

func _animate_custom_value(mode: int) -> void:
	if _input_visible == null:
		return

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

func clear_value() -> void:
	_on_ClearButton_pressed()

func set_value(value) -> void:
	if value == null:
		return

	if _input_visible is LineEdit:
		_input_visible.text = str(value)
	elif _input_visible.name == 'Vector2':
		var x: LineEdit = _input_visible.find_node('x')
		var y: LineEdit = _input_visible.find_node('y')

		if value is Array:
			x.text = str(value[0])
			y.text = str(value[1])
	elif _input_visible.name == 'Vector3':
		var x: LineEdit = _input_visible.find_node('x')
		var y: LineEdit = _input_visible.find_node('y')
		var z: LineEdit = _input_visible.find_node('z')

		if value is Array:
			x.text = str(value[0])
			y.text = str(value[1])
			z.text = str(value[2])

	_on_CurrentValue_pressed()

func get_value():
	if _input_visible == null or $CurrentValue.modulate.a > 0:
		return null

	if _input_visible is LineEdit:
		if _input_visible.has_method('get_value'):
			return _input_visible.get_value()
		
		return _input_visible.text
	elif _input_visible.name == 'Vector2':
		var x: LineEdit = _input_visible.find_node('x')
		var y: LineEdit = _input_visible.find_node('y')

		return [x.get_value(), y.get_value()]
	elif _input_visible.name == 'Vector3':
		var x: LineEdit = _input_visible.find_node('x')
		var y: LineEdit = _input_visible.find_node('y')
		var z: LineEdit = _input_visible.find_node('z')

		return [x.get_value(), y.get_value(), z.get_value()]

func set_label(new_label: String) -> void:
	if _current_value_button == null:
		_current_value_button = find_node('CurrentValue')

	label = new_label
	_current_value_button.text = label

func set_show_relative_button(relative_button: bool) -> void:
	show_relative_button = relative_button
	
	var button: Button = find_node('RelativeButton')
	button.visible = show_relative_button

func _on_CurrentValue_pressed():
	_animate_custom_value(AnimaTween.PLAY_MODE.NORMAL)

func _on_ClearButton_pressed():
	_animate_custom_value(AnimaTween.PLAY_MODE.BACKWARDS)

	emit_signal("vale_updated")

func _on_input_changed() -> void:
	emit_signal('vale_updated')

func _on_FreeText_text_changed(_new_text):
	emit_signal("vale_updated")

func _handle_custom_value_visibility(visible: bool) -> void:
	_custom_value.visible = visible

func _on_RelativeButton_pressed():
	pass # Replace with function body.
