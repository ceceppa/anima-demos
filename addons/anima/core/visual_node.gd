tool
class_name AnimaVisualNode
extends Node

export (Dictionary) var __anima_visual_editor_data

var _initial_values := {}

#
# Returns the node that Anima will use when handling the animations
# done via visual editor
#
func get_source_node() -> Node:
	var parent = self.get_parent()

	if parent == null:
		return self

	return parent

func get_animations_list() -> Array:
	var animations := []

	return __anima_visual_editor_data.animations_names

func play_animation(name: String) -> void:
	var anima: AnimaNode = Anima.begin(self)
	var animation_names := get_animations_list()
	var animation_id: int = animation_names.find(name)

	anima.set_single_shot(true)

	var data_by_animation = __anima_visual_editor_data.data_by_animation
	var animations_data = data_by_animation[animation_id] if data_by_animation.has(animation_id) else null

	if animations_data == null:
		printerr("The selected animation is empty") 

		return

	for animation in animations_data:
		var data: Dictionary = _create_animation_data(animation.node, animation.data.duration, animation.data.delay, animation.data.animation_data)

		data._wait_time = animation.start_time

		anima.with(data)

	_play_and_reset_initial_values(anima)

func preview_animation(node: Node, duration: float, delay: float, animation_data: Dictionary) -> void:
	var anima: AnimaNode = Anima.begin(self)
	anima.set_single_shot(true)

	var initial_value = null

	var anima_data = _create_animation_data(node, duration, delay, animation_data)
	AnimaUI.debug(self, 'playing node animation with data', anima_data)

	anima.then(anima_data)
	
	_play_and_reset_initial_values(anima)

func _create_animation_data(node: Node, duration: float, delay: float, animation_data: Dictionary) -> Dictionary:
	var anima_data = {
		node = node,
		duration = duration,
		delay = delay
	}

	if animation_data.type == AnimaUI.VISUAL_ANIMATION_TYPE.ANIMATION:
		anima_data.animation = animation_data.animation.name
	else:
		var node_name: String = node.name
		var property_name: String = animation_data.property.name

		if not _initial_values.has(node) or not _initial_values[node].has(property_name):
			if not _initial_values.has(node):
				_initial_values[node] = {}

			_initial_values[node][animation_data.property.name] = AnimaNodesProperties.get_property_value(node, property_name)

		for key in animation_data.property:
			if key == 'name':
				anima_data.property = animation_data.property.name
			elif key == 'pivot':
				var pivot = animation_data.property.pivot

				if pivot[0] == 1:
					anima_data.pivot = pivot[1]
			else:
				var value = animation_data.property[key]
				
				if value != null:
					anima_data[key] = animation_data.property[key]

	return anima_data

func _play_and_reset_initial_values(anima_node: AnimaNode) -> void:
	anima_node.play()

	yield(anima_node, "animation_completed")

	# reset node initial values
	if _initial_values.size() == 0:
		return

	for node in _initial_values:
		var initial_values: Dictionary = _initial_values[node]

		for property_name in initial_values:
			var initial_value = initial_values[property_name]

			var mapped_property = AnimaNodesProperties.map_property_to_godot_property(node, property_name)

			if mapped_property.has('callback'):
				mapped_property.callback.call_func(mapped_property.param, initial_value)
			elif mapped_property.has('subkey'):
				node[mapped_property.property_name][mapped_property.key][mapped_property.subkey] = initial_value
			elif mapped_property.has('key'):
				node[mapped_property.property_name][mapped_property.key] = initial_value
			else:
				node[mapped_property.property_name] = initial_value

		_initial_values.clear()
