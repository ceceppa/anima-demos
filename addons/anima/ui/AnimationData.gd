tool
extends VBoxContainer

signal select_property
signal select_animation
signal content_size_changed(new_size)
signal value_updated

onready var _animation_type_button: Button = find_node('AnimationTypeButton')
onready var _property_type_button: Button = find_node('PropertyTypeButton')
onready var _animation_container: GridContainer = find_node('AnimationContainer')
onready var _animation_button: Button = find_node('AnimationButton')
onready var _property_container: GridContainer = find_node('PropertyContainer')
onready var _property_button: Button = find_node('PropertyButton')
onready var _animation_type: Control = find_node('AnimationType')

onready var _from_value: Control = find_node('FromValue')
onready var _to_value: Control = find_node('ToValue')
onready var _relative_check: CheckBox = find_node('RelativeCheck')
onready var _property_values: VBoxContainer = find_node('PropertyValues')

var _animation_name: String
var _data_to_restore: Dictionary
var _property_type: int
var _anima_content_type: AnimaNode
var _anima_property_values: AnimaNode
var _previous_animation_type: int

func _ready():
	_property_container.hide()

	_maybe_init_anima_node()

func get_animation_data() -> Dictionary:
	var type: int = AnimaUI.VISUAL_ANIMATION_TYPE.ANIMATION

	if _property_type_button.is_pressed():
		type = AnimaUI.VISUAL_ANIMATION_TYPE.PROPERTY

	var data := {
		type = type
	}

	if type == AnimaUI.VISUAL_ANIMATION_TYPE.ANIMATION:
		data.animation = {
			label = _animation_button.text,
			name = _animation_name
		}
	else:
		data.property = {
			name = _property_button.text,
			type = _property_type,
			from = _from_value.get_value(),
			to = _to_value.get_value(),
			relative = _relative_check.pressed,
		}

	return data

func restore_data(data: Dictionary) -> void:
	if not data.has('type'):
		return

	if data.type == AnimaUI.VISUAL_ANIMATION_TYPE.ANIMATION:
		_animation_type_button.pressed = true
	else:
		_property_type_button.pressed = true

	AnimaUI.debug(self, 'restoring animation data', data, data.type)

	if data.type == AnimaUI.VISUAL_ANIMATION_TYPE.ANIMATION:
		_animation_button.text = data.animation.label
		_animation_name = data.animation.name

		return

	_property_button.text = data.property.name
	_property_type = data.property.type
	_from_value.set_type(data.property.type)
	_to_value.set_type(data.property.type)
	_from_value.set_value(data.property.from)
	_to_value.set_value(data.property.to)
	_relative_check.pressed = data.property.relative

	if _property_type_button.pressed:
		_on_PropertyTypeButton_pressed()
		
func set_animation_data(label: String, name: String) -> void:
	_animation_button.text = label
	_animation_name = name

func set_property_to_animate(name: String, type: int) -> void:
	_property_button.text = name
	_property_type = type

func _maybe_find_fields() -> void:
	if is_inside_tree():
		return

	_animation_type_button = find_node('AnimationTypeButton')
	_property_type_button = find_node('PropertyTypeButton')
	_animation_button = find_node('AnimationButton')
	_animation_container = find_node('AnimationContainer')
	_property_container = find_node('PropertyContainer')
	_property_button = find_node('PropertyButton')
	_from_value = find_node('FromValue')
	_to_value = find_node('ToValue')
	_property_values = find_node('PropertyValues')
	_animation_type = find_node('AnimationType')

	_ready()

func _on_PropertyButton_pressed():
	emit_signal("select_property")

func _on_AnimationButton_pressed():
	emit_signal("select_animation")

func _maybe_init_anima_node() -> void:
	if _anima_content_type != null:
		return

	_anima_content_type = Anima.begin(self)
	_anima_property_values = Anima.begin(_property_values)

	_anima_content_type.then({ 
		node = _animation_container,
		property = "y",
		from = 0,
		to = -20,
		duration = 0.3,
		easing = Anima.EASING.EASE_OUT_BACK 
	})
	_anima_content_type.also({
		property = "opacity",
		from = 1,
		to = 0
	})
	_anima_content_type.with({
		node = _property_container,
		property = "y",
		from = 20,
		to = 0,
		duration = 0.3,
		easing = Anima.EASING.EASE_OUT_BACK,
		on_started = [funcref(self, '_adjust_height'), [true], [false]],
	})
	_anima_content_type.also({
		property = "opacity",
		from = 0,
		to = 1
	})

	_anima_property_values.group(
		[
			{ node = _property_values.find_node('Label1') },
			{ group = _property_values.find_node('AnimateGrid') },
			{ node = _property_values.find_node('Label2') },
			{ group = _property_values.find_node('Easing') },
		],
		{
			duration = 0.15,
			items_delay = 0.015,
			animation = 'fadeInLeft',
		}
	)

	_anima_property_values.set_visibility_strategy(Anima.VISIBILITY.TRANSPARENT_ONLY, true)

func _adjust_height(calculate_property_values_height: bool) -> void:
	var new_size := 0 # _animation_container.rect_size.y

	if calculate_property_values_height and _property_type != 0:
		new_size = 20.0

		for child in _property_values.get_children():
			if child is Control:
				new_size += child.rect_size.y

	emit_signal("content_size_changed", new_size)

func _on_FromValue_vale_updated():
	emit_signal("value_updated")

func _on_ToValue_vale_updated():
	emit_signal("value_updated")

func _on_CheckBox_pressed():
	emit_signal("value_updated")

func _on_AnimationTypeButton_pressed():
	if _previous_animation_type == AnimaUI.VISUAL_ANIMATION_TYPE.ANIMATION:
		return

	_previous_animation_type = AnimaUI.VISUAL_ANIMATION_TYPE.ANIMATION

	_animate_content_type(AnimaTween.PLAY_MODE.NORMAL, true)

func _on_PropertyTypeButton_pressed():
	if _previous_animation_type == AnimaUI.VISUAL_ANIMATION_TYPE.PROPERTY:
		return

	_previous_animation_type = AnimaUI.VISUAL_ANIMATION_TYPE.PROPERTY

	_animate_content_type(AnimaTween.PLAY_MODE.BACKWARDS, false)

func _animate_content_type(direction: int, animation_container_visible) -> void:
	_maybe_init_anima_node()

	_animation_container.visible = true
	_property_container.visible = true

	if direction == AnimaTween.PLAY_MODE.NORMAL:
		_anima_content_type.play_backwards()

		if _property_values.get_child(0).modulate.a > 0:
			_anima_property_values.play_backwards_with_speed(1.3)
			
			yield(_anima_property_values, "animation_completed")
	else:
		_anima_content_type.play()

		if _property_type != 0:
			_anima_property_values.play()

	yield(_anima_content_type, "animation_completed")

	_animation_container.visible = animation_container_visible
	_property_container.visible = not _animation_container.visible

