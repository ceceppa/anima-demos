tool
extends MarginContainer

signal animation_updated
signal ui_resized
signal content_size_changed(new_size)

onready var _duration: Control = find_node('Duration')
onready var _delay: Control = find_node('Delay')
onready var _animations_container: VBoxContainer = find_node('AnimationsContainer')
onready var _animation_data: VBoxContainer = find_node('AnimationData')

var _relative_control: Control
var _source_node: Node

func get_animation_data() -> Dictionary:
	var animation_data = _animation_data.get_animation_data() if _animation_data else []
	
	_duration = find_node('Duration')
	_delay = find_node('Delay')

	var data := {
		duration = _duration.get_value(),
		delay = _delay.get_value(),
		animation_data = animation_data
	}

	return data

func restore_data(data: Dictionary) -> void:
	var animation_data: Dictionary = data.animation_data if data.has('animation_data') else {}
	var duration = data.duration if data.has('duration') else Anima.DEFAULT_DURATION
	var delay = data.delay if data.has('duration') else 0.0

	_duration.set_value(duration)
	_delay.set_value(delay)

	AnimaUI.debug(self, 'restoring data', data)
	_animation_data.restore_data(animation_data)

func populate_animatable_properties_list(source_node: Node) -> void:
	_source_node = source_node

	$AnimationsWindow.show_demo_by_type(_source_node)
	$PropertiesWindow.populate_animatable_properties_list(_source_node)

func populate_nodes_list(source: AnimaVisualNode) -> void:
	$PropertiesWindow.set_anima_visual_node(source)

func _on_AnimationsWindow_animation_selected(label: String, name: String):
	_animation_data.set_animation_data(label, name)

	emit_signal("animation_updated")

func _on_PropertiesWindow_property_selected(property_name: String, property_type: int, node_name: String):
	AnimaUI.debug(self, 'property selected', property_name, property_type, node_name)

	print(_relative_control)
	if _relative_control:
		var property: String = ":" + property_name

		if _source_node.name != node_name:
			property = node_name + property

		_relative_control.set_value(property)
	else:
		_animation_data.set_property_to_animate(property_name, property_type)

	emit_signal("animation_updated")

	_relative_control = null

func _on_AnimationData_select_animation():
	$AnimationsWindow.popup_centered()

func _on_AnimationData_value_updated():
	emit_signal("animation_updated")

func _on_AnimationData_select_property():
	$PropertiesWindow.popup_centered()

func _on_AnimationData_content_size_changed(new_size: float):
	emit_signal("content_size_changed", new_size)

func _on_AnimationData_select_easing():
	$AnimaEasingsWindow.popup_centered()

func _on_AnimaEasingsWindow_easing_selected(easing):
	_animation_data.set_easing(easing)

	emit_signal("animation_updated")

func _on_Duration_vale_updated():
	emit_signal("animation_updated")

func _on_Delay_vale_updated():
	emit_signal("animation_updated")

func _on_AnimationData_select_relative_property(relative_control: Control):
	_relative_control = relative_control

	$PropertiesWindow.popup_centered()
	$PropertiesWindow.show_nodes_list(true)
