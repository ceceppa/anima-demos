tool
extends VBoxContainer

signal select_property
signal select_animation
signal delete_animation

onready var _animation_type: OptionButton = find_node('AnimationTypeButton')
onready var _animation_container: GridContainer = find_node('AnimationContainer')
onready var _animation_button: Button = find_node('AnimationButton')
onready var _property_container: VBoxContainer = find_node('PropertyContainer')
onready var _property_button: Button = find_node('PropertyButton')
onready var _from_value: HBoxContainer = find_node('FromValue')
onready var _to_value: HBoxContainer = find_node('ToValue')

var _animation_name: String
var _data_to_restore: Dictionary
var _property_type: int

func get_animation_data() -> Dictionary:
	var data := {
		type = _animation_type.selected,
	}

	if _animation_type.selected == AnimaUI.VISUAL_ANIMATION_TYPE.ANIMATION:
		data.animation = {
			label = _animation_button.text,
			name = _animation_name
		}
	else:
		data.property = {
			name = _property_button.text,
			type = _property_type
		}

	return data

func restore_data(data: Dictionary) -> void:
	# This is called before onready and therefore _animation_type is null
	_maybe_find_fields()

	if not data.has('type'):
		return

	_animation_type.selected = data.type
	_on_AnimationTypeButton_item_selected(data.type)
	
	AnimaUI.debug(self, 'restoring animation data', data, data.type)

	if data.type == AnimaUI.VISUAL_ANIMATION_TYPE.ANIMATION:
		_animation_button.text = data.animation.label
		_animation_name = data.animation.name

		return

	_property_button.text = data.property.name
	_property_type = data.property.type
	_from_value.set_type(data.property.type)
	_to_value.set_type(data.property.type)

func set_animation_data(label: String, name: String) -> void:
	_animation_button.text = label
	_animation_name = name

func set_property_to_animate(name: String, type: int) -> void:
	_property_button.text = name
	_property_type = type

func _maybe_find_fields() -> void:
	if is_inside_tree():
		return

	_animation_type = find_node('AnimationTypeButton')
	_animation_button = find_node('AnimationButton')
	_animation_container = find_node('AnimationContainer')
	_property_container = find_node('PropertyContainer')
	_property_button = find_node('PropertyButton')
	_from_value = find_node('FromValue')
	_to_value = find_node('ToValue')

	_ready()

func _ready():
	if _animation_type.get_item_count() > 0:
		return

	_animation_type.clear()
	_animation_type.add_item("Animation")
	_animation_type.add_item("Property")
	
	_animation_type.selected = 0

	_on_AnimationTypeButton_item_selected(0)

func _on_PropertyButton_pressed():
	emit_signal("select_property")

func _on_AnimationButton_pressed():
	emit_signal("select_animation")

func _on_DeleteButton_pressed():
	emit_signal("delete_animation")

	queue_free()

func _on_AnimationTypeButton_item_selected(index):
	var animation_container_visible = index == 0

	_animation_container.visible = animation_container_visible
	_property_container.visible = not animation_container_visible
