tool
extends WindowDialog

signal property_selected(property_name, property_type)

var _animatable_properties := [{name = 'opacity', type = TYPE_REAL}]
var _anima: AnimaNode

func _init() -> void:
	_anima = Anima.begin(self)
	_anima.then({ animation = "zoomInUp", duration = 0.3 })
	_anima.set_visibility_strategy(Anima.VISIBILITY.TRANSPARENT_ONLY, true)

func popup_centered(size: Vector2 = Vector2.ZERO) -> void:
	# We need to reset the scale otherwise the window position will be wrong!
	rect_scale = Vector2(1, 1)
	
	.popup_centered(size)
	_anima.play()

func populate_animatable_properties_list(source_node: Node) -> void:
	var properties = source_node.get_property_list()
	var properties_to_ignore := [
		'pause_mode',
		'process_priority',
		'light_mask',
		'grow_horizontal',
		'grow_vertical',
		'focus_mode',
		'size_flags_horizontal',
		'size_flags_vertical'
	]
	for property in properties:
		if property.name.begins_with('_') or \
			property.hint == PROPERTY_HINT_ENUM or \
			properties_to_ignore.find(property.name) >= 0:
			continue

		if property.hint == PROPERTY_HINT_RANGE or \
			property.hint == PROPERTY_HINT_COLOR_NO_ALPHA or \
			property.type == TYPE_VECTOR2 or \
			property.type == TYPE_VECTOR3 or \
			property.type == TYPE_INT or \
			property.type == TYPE_REAL or \
			property.type == TYPE_COLOR:
			_animatable_properties.push_back({name = property.name.replace('rect_', ''), type = property.type})

	_animatable_properties.sort_custom(PropertiesSorter, "sort_by_name")

	populate_tree()

func populate_tree(filter: String = '') -> void:
	var tree: Tree = find_node('PropertiesTree')
	tree.clear()
	tree.set_hide_root(true)

	var root_item = tree.create_item()
	root_item.set_text(0, "Available properties")
	root_item.set_selectable(0, false)

	for animatable_property in _animatable_properties:
		var name = animatable_property.name
		var is_visible = filter.strip_edges().length() == 0 or name.to_lower().find(filter.to_lower().strip_edges()) >= 0

		if not is_visible:
			continue

		var item := tree.create_item(root_item)

		item.set_text(0, animatable_property.name)
		item.set_metadata(0, { type = animatable_property.type })
		item.set_icon(0, AnimaUI.get_godot_icon_for_type(animatable_property.type))

		var sub_properties := []
		if animatable_property.type == TYPE_VECTOR2:
			sub_properties = ['x', 'y']
		elif animatable_property.type == TYPE_VECTOR3:
			sub_properties = ['x', 'y', 'z']
		elif animatable_property.type == TYPE_COLOR:
			sub_properties = ['r', 'g', 'b', 'a']

		for sub_property in sub_properties:
			var sub = tree.create_item(item)

			sub.set_text(0, sub_property)
			sub.set_icon(0, AnimaUI.get_godot_icon_for_type(TYPE_REAL))

class PropertiesSorter:
	static func sort_by_name(a: Dictionary, b: Dictionary) -> bool:
		return a.name < b.name

func _on_LineEdit_text_changed(new_text: String):
	populate_tree(new_text)

func _on_PropertiesTree_item_double_clicked():
	var tree: Tree = find_node('PropertiesTree')
	var selected_item: TreeItem = tree.get_selected()
	var parent = selected_item.get_parent()
	var is_child = parent.get_parent() != null

	var property_to_animate: String = selected_item.get_text(0)

	if is_child:
		property_to_animate = parent.get_text(0) + ":" + property_to_animate

	emit_signal("property_selected", property_to_animate, selected_item.get_metadata(0).type)

	hide()

func _on_PropertiesTree_item_activated():
	_on_PropertiesTree_item_double_clicked()

func _on_PropertiesWindow_popup_hide():
	show()
	
	_anima.play_backwards_with_speed(1.5)

	yield(_anima, 'animation_completed')

	hide()
