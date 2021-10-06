tool
extends VBoxContainer

signal select_property
signal select_animation

onready var _animation_type = find_node('AnimationTypeButton')
onready var _animation_container = find_node('AnimationContainer')
onready var _property_container = find_node('PropertyContainer')
onready var _animation_button = find_node('AnimationButton')

var _animation_name: String

enum ANIMATION_TYPE {
	ANIMATION,
	PROPERTY
}

func get_animation_data() -> Dictionary:
	var data := {
		type = _animation_type.selected,
	}

	if _animation_type.selected == ANIMATION_TYPE.ANIMATION:
		data.animation = {
			label = _animation_button.text,
			name = _animation_name
		}
	else:
		data.property = {}

	return data

func restore_data(data: Dictionary) -> void:
	if not data.has('type'):
		return

	_animation_type.selected = data.type

	if data.type == ANIMATION_TYPE.ANIMATION:
		_animation_button.text = data.animation.label
		_animation_name = data.animation.name

func set_animation_data(label: String, name: String) -> void:
	_animation_button.text = label
	_animation_name = name

func _ready():
	_animation_type.add_item("Animation")
	_animation_type.add_item("Property")
	
	_animation_type.selected = 0

	_on_OptionButton_item_selected(0)

func _on_OptionButton_item_selected(index):
	var animation_container_visible = index == 0

	_animation_container.visible = animation_container_visible
	_property_container.visible = not animation_container_visible

func _on_PropertyButton_pressed():
	emit_signal("select_property")

func _on_AnimationButton_pressed():
	emit_signal("select_animation")
