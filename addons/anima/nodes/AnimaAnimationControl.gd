tool
extends MarginContainer

signal animation_updated
signal ui_resized
signal content_size_changed(new_size)

onready var _duration: LineEdit = find_node('Duration')
onready var _delay: LineEdit = find_node('Delay')
onready var _animations_container: VBoxContainer = find_node('AnimationsContainer')
onready var _animation_data: VBoxContainer = find_node('AnimationData')

func get_animations_data() -> Dictionary:
	var duration =  _duration.text if _duration else Anima.DEFAULT_DURATION
	var delay =  _delay.text if _delay else 0.0
	var animation_data = _animation_data.get_animation_data() if _animation_data else []

	var data := {
		duration = float(duration),
		delay = float(delay),
		animation_data = animation_data
	}

	return data

func restore_data(data: Dictionary) -> void:
	var animation_data: Dictionary = data.animation_data if data.has('animation_data') else {}
	var duration = data.duration if data.has('duration') else 0.5
	var delay = data.delay if data.has('duration') else 0.0

	_duration.text = str(duration)
	_delay.text = str(delay)

	AnimaUI.debug(self, 'restoring data', data)
	_animation_data.restore_data(animation_data)

func populate_animatable_properties_list(source_node: Node) -> void:
	$AnimationsWindow.show_demo_by_type(source_node)
	$PropertiesWindow.populate_animatable_properties_list(source_node)

func _on_AnimationsWindow_animation_selected(label: String, name: String):
	_animation_data.set_animation_data(label, name)

	emit_signal("animation_updated")

func _on_PropertiesWindow_property_selected(property_name: String, property_type: int):
	_animation_data.set_property_to_animate(property_name, property_type)

	emit_signal("animation_updated")

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
