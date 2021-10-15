tool
extends HBoxContainer

onready var _current_value_button: Button = find_node('CurrentValue')
onready var _custom_value: HBoxContainer = find_node('CustomValue')
onready var _delete_button: Button = find_node('DeleteButton')

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
			$CustomValue/Number.show()
		TYPE_REAL:
			$CustomValue/Real.show()
		TYPE_VECTOR2:
			$CustomValue/Vector2.show()
		TYPE_VECTOR3:
			$CustomValue/Vector3.show()
		_:
			printerr('set_type: unsupported type' + str(type))
			$CustomValue/FreeText.show()

func _on_CurrentValue_pressed():
	_current_value_button.hide()
	_custom_value.show()

func _on_DeleteButton_pressed():
	_current_value_button.show()
	_custom_value.hide()
