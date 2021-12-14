tool

class_name AnimaTween
extends Tween

signal animation_completed

const ANIMATED_ITEM = preload("res://addons/anima/core/animated_item.gd")

var _animation_data := []
var _visibility_strategy: int = Anima.VISIBILITY.IGNORE
var _callbacks := {}
var _is_backwards_animation := false
var _loop_strategy = Anima.LOOP.USE_EXISTING_RELATIVE_DATA
var _tween_completed := 0
var _root_node

enum PLAY_MODE {
	NORMAL,
	BACKWARDS,
	LOOP_IN_CIRCLE
}

func _ready():
#	connect("tween_started", self, '_on_tween_started')
	connect("tween_completed", self, '_on_tween_completed')

	#
	# By default Godot runs interpolate_property animation runs only once
	# this means that if you try to play again it won't work.
	# Possible solutions are:
	# - resetting the tween data and recreating all over again before starting the animation
	# - recreating the anima animation again before playing
	# - cheat
	#
	# Of the 3 I did prefer "cheating" making belive Godot that this tween is in a
	# repeat loop.
	# So, once all the animations are completed (_tween_completed == _animation_data.size())
	# we pause the tween, and next time we call play again we resume it and it works...
	# There is no need to recreating anything on each "loop"
	set_repeat(true)

func play(play_speed: float):
	set_speed_scale(play_speed)

	_tween_completed = 0

	resume_all()

func add_animation_data(animation_data: Dictionary, play_mode: int = PLAY_MODE.NORMAL) -> void:
	var index: String

	_animation_data.push_back(animation_data)
	index = str(_animation_data.size())

	var duration = animation_data.duration if animation_data.has('duration') else Anima.DEFAULT_DURATION

#	if animation_data.has('on_completed') and animation_data.has('_is_last_frame'):
#		_callbacks[property_key] = animation_data.on_completed

	if animation_data.has('visibility_strategy'):
		_apply_visibility_strategy(animation_data)

	var easing_points

	if animation_data.has('easing'):
		if animation_data.easing is FuncRef:
			easing_points = animation_data.easing
		else:
			easing_points = AnimaEasing.get_easing_points(animation_data.easing)

	if animation_data.has('easing_points'):
		easing_points = animation_data.easing_points

	animation_data._easing_points = easing_points
	animation_data._property_data = AnimatedUtils.calculate_from_and_to(animation_data)

	var object

	if animation_data._property_data.has('subkey'):
		object = AnimatedPropertyWithSubKeyItem.new()
	elif animation_data._property_data.has('key'):
		object = AnimatedPropertyWithKeyItem.new()
	else:
		object = AnimatedPropertyItem.new()

	object.set_animation_data(animation_data)

	var use_method: String = "animate_linear"

	if easing_points is Array:
		use_method = 'animate_with_easing_points'
	elif easing_points is String:
		use_method = 'animate_with_easing'
	elif easing_points is FuncRef:
		use_method = 'animate_with_easing_funcref'

	_is_backwards_animation = play_mode != PLAY_MODE.NORMAL

	var from := 0.0 if play_mode == PLAY_MODE.NORMAL else 1.0
	var to := 1.0 - from

	interpolate_method(
		object,
		use_method,
		from,
		to,
		duration,
		Tween.TRANS_LINEAR,
		Tween.EASE_IN_OUT,
		animation_data._wait_time
	)

#func test(a:float) -> void:
#	print(a)
#
# Given an array of frames generates the animation data using relative end value
#
# frames = [{
#	percentage = the percentage of the animation
#	to = the relative end value
#	easing_points = the easing points for the bezier curver (optional)
# }]
#
func add_relative_frames(data: Dictionary, property: String, frames: Array) -> float:
	return _add_frames(data, property, frames, true)

#
# Given an array of frames generates the animation data using absolute end value
#
# frames = [{
#	percentage = the percentage of the animation
#	to = the relative end value
#	easing_points = the easing points for the bezier curver (optional)
# }]
#
func add_frames(data: Dictionary, property: String, frames: Array) -> float:
	return _add_frames(data, property, frames)

func set_root_node(node: Node) -> void:
	_root_node = node

func _add_frames(data: Dictionary, property: String, frames: Array, relative: bool = false) -> float:
	var duration: float = data.duration if data.has('duration') else 0.0
	var _wait_time: float = data._wait_time if data.has('_wait_time') else 0.0
	var last_duration := 0.0
	var previous_frame: Dictionary

	var keys_to_ignore = ['duration', '_wait_time']
	for frame in frames:
		var percentage = frame.percentage if frame.has('percentage') else 100.0
		percentage /= 100.0

		var frame_duration = max(Anima.MINIMUM_DURATION, duration * percentage)
		var diff = frame_duration - last_duration
		var is_first_frame = true
		var is_last_frame = percentage == 1

		var animation_data = {
			property = property,
			relative = relative,
			duration = diff,
			_wait_time = _wait_time
		}
		
		# We need to restore the animation just before the node is animated
		# but we also need to consider that a node can have multiple
		# properties animated, so we need to restore it only before the first
		# animation starts
		for animation in _animation_data:
			if animation.node == data.node:
				is_first_frame = false

				if animation.has('_is_last_frame'):
					is_last_frame = false

		if is_first_frame:
			animation_data._is_first_frame = true

		if is_last_frame:
			animation_data._is_last_frame = true

		for key in frame:
			if key != 'percentage':
				animation_data[key] = frame[key]

		for key in data:
			if key == 'callback' and percentage < 1:
				animation_data.erase(key)
			elif keys_to_ignore.find(key) < 0:
				animation_data[key] = data[key]

		if animation_data.has('from') and not animation_data.has('to') and frames.size() > 1:
			previous_frame = animation_data

			continue
		elif animation_data.has('to') and not animation_data.has('from') and previous_frame.has('from'):
			animation_data.from = previous_frame.from

			previous_frame.clear()

		add_animation_data(animation_data)

		last_duration = frame_duration
		_wait_time += diff

	return _wait_time

func get_animation_data() -> Array:
	return _animation_data

func get_animations_count() -> int:
	return _animation_data.size()

func has_data() -> bool:
	return _animation_data.size() > 0

func clear_animations() -> void:
	remove_all()
	reset_all()

	_callbacks = {}
	_animation_data.clear()

func set_visibility_strategy(strategy: int) -> void:
	for animation_data in _animation_data:
		_apply_visibility_strategy(animation_data, strategy)

	_visibility_strategy = strategy

func set_loop_strategy(strategy: int) -> void:
	_loop_strategy = strategy

func reverse_animation(animation_data: Array, animation_length: float, default_duration: float):
	clear_animations()

	var data: Array = _flip_animations(animation_data.duplicate(true), animation_length, default_duration)

	for new_data in data:
		add_animation_data(new_data, PLAY_MODE.BACKWARDS)

#
# In order to flip "nested relative" animations we need to calculate what all the
# property as it would be if the animation is played normally. Only then we can calculate
# the correct relative positions, by also looking at the previous frames.
# Otherwise we would end up with broken animations when animating the same property more than
# once 
func _flip_animations(data: Array, animation_length: float, default_duration: float) -> Array:
	var new_data := []
	var previous_frames := {}
	var length: float = animation_length

	for animation in data:
		var animation_data = animation.duplicate(true)
		var duration: float = float(animation_data.duration) if animation_data.has('duration') else default_duration
		var wait_time: float = animation_data._wait_time
		var node = animation_data.node
		var new_wait_time: float = length - duration - wait_time
		var property = animation_data.property
		var is_relative = animation_data.has('relative') and animation_data.relative

		if not animation_data.has('from'):
			var node_from = AnimaNodesProperties.get_property_value(node, property)

			if previous_frames.has(node) and previous_frames[node].has(property):
				node_from = previous_frames[node][property]

			animation_data.from = node_from

		if animation_data.has('to') and is_relative:
			animation_data.to += animation_data.from
		elif not animation_data.has('to'):
			animation_data.to = AnimaNodesProperties.get_property_value(node, property)
			animation_data.__ignore_to_relative = false

		if not previous_frames.has(node):
			previous_frames[node] = {}

		if animation_data.has('to'):
			previous_frames[node][property] = animation_data.to
		else:
			previous_frames[node][property] = animation_data.from

		animation_data._wait_time = max(Anima.MINIMUM_DURATION, new_wait_time)

		var old_on_completed = animation_data.on_completed if animation_data.has('on_completed') else null
		var erase_on_completed := true

		if animation_data.has('on_started'):
			animation_data.on_completed = animation_data.on_started
			animation_data.erase('on_started')

			erase_on_completed = false

		if old_on_completed:
			animation_data.on_started = old_on_completed

			if erase_on_completed:
				animation_data.erase('on_completed')

		new_data.push_back(animation_data)

	return new_data

func _apply_visibility_strategy(animation_data: Dictionary, strategy: int = Anima.VISIBILITY.IGNORE):
	if not animation_data.has('_is_first_frame'):
		return

	var should_hide_nodes := false
	var should_make_nodes_transparent := false

	if animation_data.has("visibility_strategy"):
		strategy = animation_data.visibility_strategy

	if strategy == Anima.VISIBILITY.HIDDEN_ONLY:
		should_hide_nodes = true
	elif strategy == Anima.VISIBILITY.HIDDEN_AND_TRANSPARENT:
		should_hide_nodes = true
		should_make_nodes_transparent = true
	elif strategy == Anima.VISIBILITY.TRANSPARENT_ONLY:
		should_make_nodes_transparent = true

	var node: Node = animation_data.node

	if should_hide_nodes:
		node.show()

	if should_make_nodes_transparent and 'modulate' in node:
		var modulate = node.modulate
		var transparent = modulate

		transparent.a = 0
		node.set_meta('_old_modulate', modulate)

		node.modulate = transparent

		if animation_data.has('property') and animation_data.property == 'opacity':
			node.remove_meta('_old_modulate')

func _on_animation_with_key(index: int, elapsed: float) -> void:
	var data = _calculate_value(index, elapsed)

	data.node[data.property_name][data.key] = data.value

func _on_animation_with_subkey(index: int, elapsed: float) -> void:
	var data = _calculate_value(index, elapsed)

	data.node[data.property_name][data.key][data.subkey] = data.value

func _calculate_value(index: int, elapsed: float) -> Dictionary:
	var animation_data = _animation_data[index]
	var property_data = _animation_data[index]._property_data
	var node = animation_data.node
	var value = property_data.from + (property_data.diff * elapsed)

	return {
		node = node,
		property_name = property_data.property_name,
		key = property_data.key,
		subkey = property_data.subkey if property_data.has('subkey') else null,
		value = value
	}

func _on_animation_without_key(index: int, elapsed: float) -> void:
	var animation_data = _animation_data[index]
	var property_data = _animation_data[index]._property_data
	var node = animation_data.node
	var is_rect2 = property_data.from is Rect2
	var value
	
	if is_rect2:
		value = Rect2(
			property_data.from.position + (property_data.diff.position * elapsed),
			property_data.from.size + (property_data.diff.size * elapsed)
		)
	else:
		value = property_data.from + (property_data.diff * elapsed)

	if property_data.has('callback'):
		property_data.callback.call_func(property_data.param, value)

		return

	node[property_data.property_name] = value

# We don't want the user to specify the from/to value as color
# we animate opacity.
# So this function converts the "from = #" -> Color(.., .., .., #)
# same for the to value
#
func _maybe_adjust_modulate_value(animation_data: Dictionary, value):
	var property = animation_data.property
	var node = animation_data.node

	if not property == 'opacity':
		return value

	if value is int or value is float:
		var color = node.modulate

		color.a = value

		return color

	return value

func _on_tween_completed(_ignore, property_name: String) -> void:
#	var index := _get_animation_data_index(property_name)
#	var property_key = property_name.replace(':_fake_property:', '')
#
#	if _callbacks.has(property_key):
#		_execute_callback(_callbacks[property_key])
#
	_tween_completed += 1

	if _tween_completed >= _animation_data.size():
		stop_all()

		emit_signal("animation_completed")

func _on_tween_started(_ignore, key) -> void:
	print("started")
#	var index := _get_animation_data_index(key)
#	var visibility_strategy = _visibility_strategy
#	var animation_data = _animation_data[index]
#
#	if animation_data.has("visibility_strategy"):
#		visibility_strategy = animation_data.visibility_strategy
#
#	var node: Node = animation_data.node
#	var should_restore_visibility := false
#	var should_restore_modulate := false
#
#	if visibility_strategy == Anima.VISIBILITY.HIDDEN_ONLY:
#		should_restore_visibility = true
#	elif visibility_strategy == Anima.VISIBILITY.HIDDEN_AND_TRANSPARENT:
#		should_restore_modulate = true
#		should_restore_visibility = true
#	elif visibility_strategy == Anima.VISIBILITY.TRANSPARENT_ONLY:
#		should_restore_modulate = true
#
#	if should_restore_modulate:
#		var old_modulate
#
#		if node.has_meta('_old_modulate'):
#			old_modulate = node.get_meta('_old_modulate')
#			old_modulate.a = 1.0
#
#		if old_modulate:
#			node.modulate = old_modulate
#
#	if should_restore_visibility:
#		node.show()
#
#	var should_trigger_on_started: bool = animation_data.has('_is_first_frame') and animation_data._is_first_frame and animation_data.has('on_started')
#	if should_trigger_on_started:
#		_execute_callback(animation_data.on_started)
	pass

func _execute_callback(callback) -> void:
	var fn: FuncRef
	var args: Array = []

	if callback is Array:
		fn = callback[0]
		args = callback[1]

		if _is_backwards_animation:
			args = callback[2]
	else:
		fn = callback
		
	fn.call_funcv(args)


class AnimatedUtils:
#	static func calculate_from_and_to(animation_data: Dictionary, loop_strategy: int) -> void:
#		var node: Node = animation_data.node
#
#		var do_calculate := true
#		var recalculate_from_to = loop_strategy == Anima.LOOP.RECALCULATE_RELATIVE_DATA and animation_data.has('relative')
#
#		if recalculate_from_to == false and animation_data.has('_property_data'):
#			do_calculate = false
#
#		if do_calculate:
#			_do_calculate_from_to(node, animation_data)
#
#		var callback := 'animate_property'
#
#		if animation_data._property_data.has('subkey'):
#			callback = 'animate_property_with_subkey'
#		elif animation_data._property_data.has('key'):
#			callback = 'animate_property_with_key'
#
#		animation_data._animation_callback = callback
	static func calculate_from_and_to(animation_data: Dictionary) -> Dictionary:
		var node: Node = animation_data.node
		var from
		var to
		var relative = animation_data.relative if animation_data.has('relative') else false
		var node_from = AnimaNodesProperties.get_property_value(node, animation_data.property)
		var property_data: Dictionary

		if animation_data.has('from'):
			from = _maybe_calculate_value(animation_data.from, animation_data)
			from = _maybe_convert_from_deg_to_rad(node, animation_data, from)
			from = _maybe_calculate_relative_value(relative, from, node_from)
		else:
			from = node_from

		if animation_data.has('to'):
			var start = node_from #if _is_backwards_animation else from
			var to_relative = false if animation_data.has('__ignore_to_relative') else relative

			to = _maybe_calculate_value(animation_data.to, animation_data)
			to = _maybe_convert_from_deg_to_rad(node, animation_data, to)
			to = _maybe_calculate_relative_value(to_relative, to, start)
		else:
			to = node_from

		if animation_data.has('pivot'):
			if node is Spatial:
				printerr('3D Pivot not supported yet')
			else:
				AnimaNodesProperties.set_2D_pivot(animation_data.node, animation_data.pivot)

		property_data = AnimaNodesProperties.map_property_to_godot_property(node, animation_data.property)

		if typeof(to) == TYPE_RECT2:
			property_data.diff = { position = to.position - from.position, size = to.size - from.size }
		else:
			property_data.diff = to - from

		property_data.from = from
		property_data.to = to

		return property_data

	static func _maybe_calculate_value(value, animation_data: Dictionary):
		if (not value is String and not value is Array) or (value is String and value.find(':') < 0):
			return value

		var values_to_check: Array

		if value is String:
			values_to_check.push_back(value)
		else:
			values_to_check = value

		var regex := RegEx.new()
		regex.compile("([\\w\\/.:]+[a-zA-Z]*:[a-z]*:?[a-z]*)")

		var all_results := []
		var root = null #_root_node #if _root_node else get_viewport()

		for single_value in values_to_check:
			if single_value == "":
				single_value = "0.0"

			var results := regex.search_all(single_value)
			var variables := []
			var values := []

			results.invert()

			for index in results.size():
				var rm: RegExMatch = results[index]
				var info: Array = rm.get_string().split(":")
				var source = info.pop_front()
				var source_node: Node

				if source == '':
					source_node = animation_data.node
				else:
					source_node = root.get_node(source)

				var property: String = PoolStringArray(info).join(":")
				var property_value = AnimaNodesProperties.get_property_value(source_node, property)

				AnimaUI.debug("AnimatedItem", "_maybe_calculate_value: search", source_node, rm.get_string(), property, property_value)

				var variable := char(65 + index)

				variables.push_back(variable)
				values.push_back(property_value)

				single_value.erase(rm.get_start(), rm.get_end() - rm.get_start())
				single_value = single_value.insert(rm.get_start(), variable)

			var expression := Expression.new()
			expression.parse(single_value, variables)

			var result = expression.execute(values)

			all_results.push_back(result)
			AnimaUI.debug("AnimatedItem", "-->", value, result)

		if value is String:
			return all_results[0]

		if all_results.size() == 2:
			return Vector2(all_results[0], all_results[1])
		elif all_results.size() == 3:
			return Vector3(all_results[0], all_results[1], all_results[2])
		elif all_results.size() == 4:
			return Rect2(all_results[0], all_results[1], all_results[2], all_results[3])

		return all_results

	static func _maybe_calculate_relative_value(relative, value, current_node_value):
		if not relative:
			return value

		if value is Rect2:
			value.position += current_node_value.position
			value.size += current_node_value.size

			return value

		return value + current_node_value

	static func _maybe_convert_from_deg_to_rad(node: Node, animation_data: Dictionary, value):
		if not node is Spatial or animation_data.property.find('rotation') < 0:
			return value

		if value is Vector3:
			return Vector3(deg2rad(value.x), deg2rad(value.y), deg2rad(value.z))

		return deg2rad(value)

class AnimatedItem extends Node:
	var _node: Node
	var _property: String
	var _key
	var _subKey
	var _animation_data: Dictionary
	var _loop_strategy: int = Anima.LOOP.USE_EXISTING_RELATIVE_DATA
	var _is_backwards_animation: bool = false
	var _root_node: Node
	var _animation_callback: FuncRef

	func set_animation_data(data: Dictionary) -> void:
		_animation_data = data

		var p_data: Dictionary = data._property_data
		_property = p_data.property_name
		_key = p_data.key if p_data.has("key") else null
		_subKey = p_data.subkey if p_data.has("subkey") else null

		_node = data.node

	func animate(elapsed: float) -> void:
		var property_data = _animation_data._property_data
		var value = property_data.from + (property_data.diff * elapsed)

		apply_value(value)

	func apply_value(value) -> void:
		printerr("Please use LinearAnimatedItem or EasingAnimatedItem class intead!!!")

	func animate_with_easing(elapsed: float):
		var easing_points = _animation_data._easing_points
		var p1 = easing_points[0]
		var p2 = easing_points[1]
		var p3 = easing_points[2]
		var p4 = easing_points[3]

		var easing_elapsed = _cubic_bezier(Vector2.ZERO, Vector2(p1, p2), Vector2(p3, p4), Vector2(1, 1), elapsed)

		animate(easing_elapsed)

	func animate_with_easing_points(elapsed: float):
		var easing_points_function = _animation_data._easing_points
		var easing_callback = funcref(AnimaEasing, easing_points_function)
		var easing_elapsed = easing_callback.call_func(elapsed)

		animate(easing_elapsed)

	func animate_with_easing_funcref(elapsed: float):
		var easing_callback = _animation_data._easing_points
		var easing_elapsed = easing_callback.call_func(elapsed)

		animate(easing_elapsed)

	func animate_linear(elapsed: float):
		animate(elapsed)

	func _cubic_bezier(p0: Vector2, p1: Vector2, p2: Vector2, p3: Vector2, t: float) -> float:
		var q0 = p0.linear_interpolate(p1, t)
		var q1 = p1.linear_interpolate(p2, t)
		var q2 = p2.linear_interpolate(p3, t)

		var r0 = q0.linear_interpolate(q1, t)
		var r1 = q1.linear_interpolate(q2, t)

		var s = r0.linear_interpolate(r1, t)

		return s.y

class AnimatedPropertyItem extends AnimatedItem:
	func apply_value(value) -> void:
		_node[_property] = value

class AnimatedPropertyWithKeyItem extends AnimatedItem:
	func apply_value(value) -> void:
		_node[_property][_key] = value

class AnimatedPropertyWithSubKeyItem extends AnimatedItem:
	func apply_value(value) -> void:
		_node[_property][_key][_subKey] = value
