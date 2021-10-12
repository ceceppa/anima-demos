tool
extends PanelContainer

signal select_property
signal select_animation
signal delete_animation

onready var _animation_type: OptionButton = find_node('AnimationTypeButton')
onready var _animation_container: GridContainer = find_node('AnimationContainer')
onready var _property_container: GridContainer = find_node('PropertyContainer')
onready var _animation_button: Button = find_node('AnimationButton')

var _animation_name: String
var _data_to_restore: Dictionary

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
		data.property = {}

	return data

func restore_data(data: Dictionary) -> void:
	# This is called before onready and therefore _animation_type is null
	if not is_inside_tree():
		_animation_type = find_node('AnimationTypeButton')
		_animation_button = find_node('AnimationButton')

	if not data.has('type'):
		return

	_animation_type.selected = data.type

	if data.type == AnimaUI.VISUAL_ANIMATION_TYPE.ANIMATION:
		_animation_button.text = data.animation.label
		_animation_name = data.animation.name

func set_animation_data(label: String, name: String) -> void:
	_animation_button.text = label
	_animation_name = name

func _ready():
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
