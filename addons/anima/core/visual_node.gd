tool
class_name AnimaVisualNode
extends Node

signal animation_completed

export (Dictionary) var __anima_visual_editor_data

var _initial_values := {}
var _active_anima_node: AnimaNode

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

	if __anima_visual_editor_data.has('animations'):
		return __anima_visual_editor_data.animations

	return []

func play_animation(name: String, speed: float = 1.0, reset_initial_values := false) -> void:
	var animations_data: Dictionary = _get_animation_data_by_name(name)

	if animations_data.size() == 0:
		printerr("The selected animation is empty") 

		return

	_play_animation_from_data(animations_data, speed, reset_initial_values)

func _get_animation_data_by_name(animation_name: String) -> Dictionary:
	var animations := get_animations_list()
	var data_by_animation = __anima_visual_editor_data.data_by_animation

	if data_by_animation == null:
		return {}

	for animation_id in animations.size():
		var animation: Dictionary = animations[animation_id]

		if animation.name == animation_name:
			return {
				data = data_by_animation[animation_id],
				visibility_strategy = animation.visibility_strategy
			}

	return {}

func _play_animation_from_data(animations_data: Dictionary, speed: float, reset_initial_values: bool) -> void:
	var anima: AnimaNode = Anima.begin(self)
	var visibility_strategy: int = animations_data.visibility_strategy
	var timeline_debug := {}
	
	anima.set_single_shot(true)
	anima.set_root_node(get_source_node())
	anima.set_visibility_strategy(visibility_strategy)

	var source_node: Node = get_source_node()

	for animation in animations_data.data:
		var node_path: String = animation.node_path
		var node: Node = source_node.get_node(node_path)
		
		AnimaUI.debug(self, "getting node from path:", node_path, node)
		var data: Dictionary = _create_animation_data(node, animation.data.duration, animation.data.delay, animation.data.animation_data)

		data._wait_time = animation.start_time

		if not timeline_debug.has(data._wait_time):
			timeline_debug[data._wait_time] = []

		var what = data.property if data.has("property") else data.animation

		timeline_debug[data._wait_time].push_back({ duration = data.duration, delay = data.delay, what = what })
		anima.with(data)

	var keys = timeline_debug.keys()
	keys.sort()

	for k in keys:
		for d in timeline_debug[k]:
			var s: float = k + d.delay
			print(".".repeat(s * 10), "▒".repeat(float(d.duration) * 10), " --> ", "from: ", s, " to: ", s + d.duration, " => ", d.what)

	_active_anima_node = anima
	anima.play_with_speed(speed)

	yield(anima, "animation_completed")

	if reset_initial_values:
		_reset_initial_values()

	emit_signal("animation_completed")

func preview_animation(node: Node, duration: float, delay: float, animation_data: Dictionary) -> void:
	var anima: AnimaNode = Anima.begin(self)
	anima.set_single_shot(true)

	var initial_value = null

	var anima_data = _create_animation_data(node, duration, delay, animation_data)
	anima.set_root_node(get_source_node())

	AnimaUI.debug(self, 'playing node animation with data', anima_data)

	anima.then(anima_data)

	anima.play()
	yield(anima, "animation_completed")

	_reset_initial_values()

func stop() -> void:
	if _active_anima_node == null:
		return

	_active_anima_node.stop()
	_reset_initial_values()

func _create_animation_data(node: Node, duration: float, delay: float, animation_data: Dictionary) -> Dictionary:
	var anima_data = {
		node = node,
		duration = duration,
		delay = delay
	}
	var properties_to_reset := ["opacity", "position", "size", "rotation", "scale"]

	if animation_data.type == AnimaUI.VISUAL_ANIMATION_TYPE.ANIMATION:
		anima_data.animation = animation_data.animation.name
	else:
		var node_name: String = node.name
		var property_name: String = animation_data.property.name
		properties_to_reset.clear()
		properties_to_reset.push_back(animation_data.property.name)

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

	for property in properties_to_reset:
		if not _initial_values.has(node) or not _initial_values[node].has(property):
			if not _initial_values.has(node):
				_initial_values[node] = {}

			_initial_values[node][property] = AnimaNodesProperties.get_property_value(node, property)

	return anima_data

func _reset_initial_values() -> void:
	_active_anima_node = null

	yield(get_tree().create_timer(1.0), "timeout")

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
