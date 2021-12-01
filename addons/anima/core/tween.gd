tool

class_name AnimaTween
extends Tween

signal animation_completed

var _animation_data := []

# Needed to use interpolate_property
var _fake_property: Dictionary = {}

var _visibility_strategy: int = Anima.VISIBILITY.IGNORE
var _callbacks := {}
var _is_backwards_animation := false
var _loop_strategy = Anima.LOOP.USE_EXISTING_RELATIVE_DATA
var _tween_completed := 0

enum PLAY_MODE {
	NORMAL,
	BACKWARDS,
	LOOP_IN_CIRCLE
}

func _ready():
	connect("tween_started", self, '_on_tween_started')
	connect("tween_step", self, '_on_tween_step_with_easing')
	connect("tween_step", self, '_on_tween_step_with_easing_callback')
	connect("tween_step", self, '_on_tween_step_with_easing_funcref')
	connect("tween_step", self, '_on_tween_step_without_easing')
	connect("tween_completed", self, '_on_tween_completed')

	#
	# By default Godot runs interpolate_property animation runs only once
	# this means that if you try to play again it won't work.
	# Possible solutions are:
	# - resetting the tween data and recreating all over again before starting the animation
	# - recreating the anima animation again before playing
	# - cheat
	#
	# Of the 3 I did prefer "chating" making belive Godot that this tween is in a
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
	var property_key = 'p' + index

	_fake_property[property_key] = 0.0

	if animation_data.has('on_completed') and animation_data.has('_is_last_frame'):
		_callbacks[property_key] = animation_data.on_completed

	if animation_data.has('hide_strategy'):
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

	animation_data._animation_callback = funcref(self, '_calculate_from_and_to')

	if easing_points is Array:
		animation_data._use_step_callback = '_on_tween_step_with_easing'
	elif easing_points is String:
		animation_data._use_step_callback = '_on_tween_step_with_easing_callback'
	elif easing_points is FuncRef:
		animation_data._use_step_callback = '_on_tween_step_with_easing_funcref'
	else:
		animation_data._use_step_callback = '_on_tween_step_without_easing'

	_is_backwards_animation = play_mode != PLAY_MODE.NORMAL

	var from := 0.0 if play_mode == PLAY_MODE.NORMAL else 1.0
	var to := 1.0 - from

	interpolate_property(
		self,
		'_fake_property:' + property_key,
		from,
		to,
		duration,
		Tween.TRANS_LINEAR,
		Tween.EASE_IN_OUT,
		animation_data._wait_time
	)

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

	_fake_property = {}
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

	if animation_data.has('hide_strategy'):
		strategy = animation_data.hide_strategy

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

func _on_tween_step_with_easing(object: Object, key: NodePath, _time: float, elapsed: float):
	var index := _get_animation_data_index(key)

	if _animation_data[index]._use_step_callback != '_on_tween_step_with_easing':
		return

	var animation_data = _animation_data[index]
	var easing_points = animation_data._easing_points
	var p1 = easing_points[0]
	var p2 = easing_points[1]
	var p3 = easing_points[2]
	var p4 = easing_points[3]

	var easing_elapsed = _cubic_bezier(Vector2.ZERO, Vector2(p1, p2), Vector2(p3, p4), Vector2(1, 1), elapsed)

	animation_data._animation_callback.call_func(index, easing_elapsed)

func _on_tween_step_with_easing_callback(object: Object, key: NodePath, _time: float, elapsed: float):
	var index := _get_animation_data_index(key)

	if _animation_data[index]._use_step_callback != '_on_tween_step_with_easing_callback':
		return

	var easing_points_function = _animation_data[index]._easing_points
	var easing_callback = funcref(AnimaEasing, easing_points_function)
	var easing_elapsed = easing_callback.call_func(elapsed)

	_animation_data[index]._animation_callback.call_func(index, easing_elapsed)

func _on_tween_step_with_easing_funcref(object: Object, key: NodePath, _time: float, elapsed: float):
	var index := _get_animation_data_index(key)

	if _animation_data[index]._use_step_callback != '_on_tween_step_with_easing_funcref':
		return

	var easing_callback = _animation_data[index]._easing_points
	var easing_elapsed = easing_callback.call_func(elapsed)

	_animation_data[index]._animation_callback.call_func(index, easing_elapsed)

func _on_tween_step_without_easing(object: Object, key: NodePath, _time: float, elapsed: float):
	var index := _get_animation_data_index(key)

	if _animation_data[index]._use_step_callback != '_on_tween_step_without_easing':
		return

	_animation_data[index]._animation_callback.call_func(index, elapsed)

func _get_animation_data_index(key: NodePath) -> int:
	var s = str(key)

	return int(s.replace('_fake_property:p', '')) - 1

func _cubic_bezier(p0: Vector2, p1: Vector2, p2: Vector2, p3: Vector2, t: float) -> float:
	var q0 = p0.linear_interpolate(p1, t)
	var q1 = p1.linear_interpolate(p2, t)
	var q2 = p2.linear_interpolate(p3, t)

	var r0 = q0.linear_interpolate(q1, t)
	var r1 = q1.linear_interpolate(q2, t)

	var s = r0.linear_interpolate(r1, t)

	return s.y

func _calculate_from_and_to(index: int, value: float) -> void:
	var animation_data: Dictionary = _animation_data[index]
	var node: Node = animation_data.node

	var do_calculate := true
	var recalculate_from_to = _loop_strategy == Anima.LOOP.RECALCULATE_RELATIVE_DATA and animation_data.has('relative')
	
	if recalculate_from_to == false and animation_data.has('_property_data'):
		do_calculate = false

	if do_calculate:
		_do_calculate_from_to(node, animation_data)
		_animation_data[index] = animation_data

	var callback := '_on_animation_without_key'

	if animation_data._property_data.has('subkey'):
		callback = '_on_animation_with_subkey'
	elif animation_data._property_data.has('key'):
		callback = '_on_animation_with_key'

	animation_data._animation_callback = funcref(self, callback)

	_animation_data[index]._animation_callback.call_func(index, value)

func _do_calculate_from_to(node: Node, animation_data: Dictionary) -> void:
	var from
	var to
	var relative = animation_data.relative if animation_data.has('relative') else false
	var node_from = AnimaNodesProperties.get_property_value(node, animation_data.property)

	if animation_data.has('from'):
		from = _maybe_calculate_value(animation_data.from, animation_data)
		from = _maybe_convert_from_deg_to_rad(node, animation_data, from)
		from = _maybe_calculate_relative_value(relative, from, node_from)
	else:
		from = node_from
		animation_data.__from = from

	if animation_data.has('to'):
		var start = node_from if _is_backwards_animation else from
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

	animation_data._property_data = AnimaNodesProperties.map_property_to_godot_property(node, animation_data.property)

	if to is Rect2:
		animation_data._property_data.diff = { position = to.position - from.position, size = to.size - from.size }
	else:
		animation_data._property_data.diff = to - from

	animation_data._property_data.from = from
	animation_data._property_data.to = to

func _maybe_calculate_value(value, animation_data: Dictionary):
	if not value is String or value.find(':') < 0:
		return value

	var regex := RegEx.new()
	regex.compile("(:?[a-z]*:[a-z]*:?[a-z]*)")

	var results := regex.search_all(value)
	var variables := []
	var values := []

	results.invert()

	for index in results.size():
		var rm: RegExMatch = results[index]
		var info: Array = rm.get_string().split(":")
		var source_node = info.pop_front()

		if source_node == '':
			source_node = animation_data.node
		else:
			source_node = get_viewport().find_node(source_node, true, false)

		var property: String = PoolStringArray(info).join(":")
		var property_value = AnimaNodesProperties.get_property_value(source_node, property)

		AnimaUI.debug(self, "_maybe_calculate_value: search", source_node, rm.get_string(), property, property_value)

		var variable := char(65 + index)

		variables.push_back(variable)
		values.push_back(property_value)
		
		value.erase(rm.get_start(), rm.get_end() - rm.get_start())
		value = value.insert(rm.get_start(), variable)

	var expression := Expression.new()
	expression.parse(value, variables)

	var result = expression.execute(values)

	AnimaUI.debug(self, "-->", value, result)

	return result

func _maybe_calculate_relative_value(relative, value, current_node_value):
	if not relative:
		return value

	return value + current_node_value

func _maybe_convert_from_deg_to_rad(node: Node, animation_data: Dictionary, value):
	if not node is Spatial or animation_data.property.find('rotation') < 0:
		return value

	if value is Vector3:
		return Vector3(deg2rad(value.x), deg2rad(value.y), deg2rad(value.z))

	return deg2rad(value)

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
	var index := _get_animation_data_index(property_name)
	var property_key = property_name.replace(':_fake_property:', '')

	if _callbacks.has(property_key):
		_execute_callback(_callbacks[property_key])

	_tween_completed += 1

	if _tween_completed >= _animation_data.size():
		stop_all()

		emit_signal("animation_completed")

func _on_tween_started(_ignore, key) -> void:
	var index := _get_animation_data_index(key)
	var hide_strategy = _visibility_strategy
	var animation_data = _animation_data[index]

	if animation_data.has('hide_strategy'):
		hide_strategy = animation_data.hide_strategy

	var node: Node = animation_data.node
	var should_restore_visibility := false
	var should_restore_modulate := false

	if hide_strategy == Anima.VISIBILITY.HIDDEN_ONLY:
		should_restore_visibility = true
	elif hide_strategy == Anima.VISIBILITY.HIDDEN_AND_TRANSPARENT:
		should_restore_modulate = true
		should_restore_visibility = true
	elif hide_strategy == Anima.VISIBILITY.TRANSPARENT_ONLY:
		should_restore_modulate = true

	if should_restore_modulate:
		var old_modulate
		
		if node.has_meta('_old_modulate'):
			old_modulate = node.get_meta('_old_modulate')
			old_modulate.a = 1.0

		if old_modulate:
			node.modulate = old_modulate

	if should_restore_visibility:
		node.show()

	var should_trigger_on_started: bool = animation_data.has('_is_first_frame') and animation_data._is_first_frame and animation_data.has('on_started')
	if should_trigger_on_started:
		_execute_callback(animation_data.on_started)

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
