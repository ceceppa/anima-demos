tool
extends MarginContainer

const ANIMATION_DATA = preload("res://addons/anima/ui/AnimationData.tscn")

signal animation_updated

onready var _duration: LineEdit = find_node('Duration')
onready var _delay: LineEdit = find_node('Delay')
onready var _animations_container: VBoxContainer = find_node('AnimationsContainer')

var _source_animation_data: PanelContainer

func get_animations_data() -> Dictionary:
	var data := {
		duration = float(_duration.text),
		delay = float(_delay.text),
		animations = []
	}

	for child in _animations_container.get_children():
		if not child.is_queued_for_deletion():
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
		child.queue_free()

	for animation in animations:
		var animation_data = ANIMATION_DATA.instance()

		animation_data.connect("select_animation", self, "_on_select_animation", [animation_data])
		animation_data.connect("select_property", self, "_on_select_property", [animation_data])
		animation_data.connect("delete_animation", self, "_on_delete_animation")

		animation_data.restore_data(animation)

		_animations_container.add_child(animation_data)

func populate_animatable_properties_list(source_node: Node) -> void:
	$AnimationsWindow.show_demo_by_type(source_node)
	$PropertiesWindow.populate_animatable_properties_list(source_node)

func _on_AnimationData_select_property():
	$PropertiesWindow.popup_centered()

func _on_AnimationsWindow_animation_selected(label: String, name: String):
	_source_animation_data.set_animation_data(label, name)

	emit_signal("animation_updated")

func _on_select_animation(source_animation_data: PanelContainer) -> void:
	_source_animation_data = source_animation_data

	$AnimationsWindow.popup_centered()

func _on_delete_animation() -> void:
	emit_signal("animation_updated")

func _on_select_property(source_animation_data: PanelContainer) -> void:
	_source_animation_data = source_animation_data

	$PropertiesWindow.popup_centered()

func _on_PropertiesWindow_property_selected(property_name: String, property_type: int):
	_source_animation_data.set_property_to_animate(property_name, property_type)

	emit_signal("animation_updated")
