tool
extends MarginContainer

func populate_animatable_properties_list(source_node: Node) -> void:
	var properties = source_node.get_property_list()

	for property in properties:
		if property.name.begins_with('_'):
			continue

		if property.hint != PROPERTY_HINT_RANGE or \
			property.hint != PROPERTY_HINT_COLOR_NO_ALPHA:
			print(property)

func _on_AnimationData_select_property():
	$PropertiesWindow.popup_centered()

func _on_AnimationData_select_animation():
	$AnimationsWindow.popup_centered()
