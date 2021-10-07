tool
extends MarginContainer

const ANIMATION_DATA = preload("res://addons/anima/ui/AnimationData.tscn")

signal animation_updated

onready var _duration: LineEdit = find_node('Duration')
onready var _delay: LineEdit = find_node('Delay')
onready var _animations_container = find_node('AnimationsContainer')

var _source_animation_data: VBoxContainer

func get_animations_data() -> Dictionary:
	var data := {
		duration = float(_duration.text),
		delay = float(_delay.text),
		animations = []
	}

	for child in _animations_container.get_children():
		data.animations.push_back(child.get_animation_data())

	return data

func restore_data(data: Dictionary) -> void:
	var animations: Array = data.animations if data.has('animations') else []
	var duration = data.duration if data.has('duration') else 0.5
	var delay = data.delay if data.has('duration') else 0.0

	_duration.text = str(duration)
	_delay.text = str(delay)

	if animations.size() == 0:
		animations.push_back({})

	print('restoring data', data)
	for child in _animations_container.get_children():
		print(child)
		child.queue_free()

	for animation in animations:
		var animation_data = ANIMATION_DATA.instance()

		animation_data.connect("select_animation", self, "_on_select_animation", [animation_data])
		animation_data.restore_data(animation)

		_animations_container.add_child(animation_data)

func populate_animatable_properties_list(source_node: Node) -> void:
	var properties = source_node.get_property_list()

	for property in properties:
		if property.name.begins_with('_'):
			continue

		if property.hint != PROPERTY_HINT_RANGE or \
			property.hint != PROPERTY_HINT_COLOR_NO_ALPHA:
			pass
#			print(property)

	$AnimationsWindow.show_demo_by_type(source_node)

func _on_AnimationData_select_property():
	$PropertiesWindow.popup_centered()

func _on_AnimationsWindow_animation_selected(label: String, name: String):
	_source_animation_data.set_animation_data(label, name)

	emit_signal("animation_updated")

func _on_select_animation(source_animation_data: VBoxContainer) -> void:
	_source_animation_data = source_animation_data

	$AnimationsWindow.popup_centered()
