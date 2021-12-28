tool

class_name AnimaTween
extends Tween

signal animation_completed

const POSITION_PROPERTIES := ['position', 'x', 'y', 'z', 'position:x', 'position:y', 'position:z']

var _animation_data := []
var _visibility_strategy: int = Anima.VISIBILITY.IGNORE
var _callbacks := {}
var _loop_strategy = Anima.LOOP.USE_EXISTING_RELATIVE_DATA
var _tween_completed := 0
var _tween_started := 0
var _root_node

enum PLAY_MODE {
	NORMAL,
	BACKWARDS,
	LOOP_IN_CIRCLE
}

func _ready():
	connect("tween_started", self, '_on_tween_started')
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
	var is_backwards_animation = play_mode != PLAY_MODE.NORMAL

	_animation_data.push_back(animation_data)
	index = str(_animation_data.size())

	var duration = animation_data.duration if animation_data.has('duration') else Anima.DEFAULT_DURATION

	if animation_data.has('visibility_strategy'):
		_apply_visibility_strategy(animation_data)

	var easing_points

	if animation_data.has('easing') and not animation_data.easing == null:
		if animation_data.easing is FuncRef or animation_data.easing is Array:
			easing_points = animation_data.easing
		else:
			easing_points = AnimaEasing.get_easing_points(animation_data.easing)

	animation_data._easing_points = easing_points
	var property_data = 	AnimaNodesProperties.map_property_to_godot_property(animation_data.node, animation_data.property)

	if not property_data.has("property_name"):
		return

	var relative = animation_data.has("relative") and animation_data.relative

	var object: Node = _get_animated_object_item(property_data, relative)

	var use_method: String = "animate_linear"

	if easing_points is Array:
		use_method = 'animate_with_easing'
	elif easing_points is String:
		use_method = 'animate_with_anima_easing'
	elif easing_points is FuncRef:
		use_method = 'animate_with_easing_funcref'

	var from := 0.0 if play_mode == PLAY_MODE.NORMAL else 1.0
	var to := 1.0 - from

	object.set_animation_data(animation_data, property_data, is_backwards_animation, _visibility_strategy)

	interpolate_method(
		object,
		use_method,
		0.0,
		1.0,
		duration,
		Tween.TRANS_LINEAR,
		Tween.EASE_IN_OUT,
		animation_data._wait_time
	)

func _get_animated_object_item(property_data: Dictionary, is_relative: bool) -> Node:
	var is_rect2 = property_data.has("is_rect2") and property_data.is_rect2
	var is_object = property_data.has("is_object") and property_data.is_object

	if is_rect2:
		return AnimateRect2.new()
	elif is_object:
		return AnimateObject.new()
	elif property_data.has('subkey'):
		return AnimatedPropertyWithSubKeyItem.new()
	elif property_data.has('key'):
		return AnimatedPropertyWithKeyItem.new()

	return AnimatedPropertyItem.new()

# Needed for animations created via the Visual Editor
func set_root_node(node: Node) -> void:
	_root_node = node

#
# Given an CSS-Keyframe like Dictionary of frames generates the animation frames
#
#	0: {
#		opacity = 0,
#		scale = Vector2(0.3, 0.3),
#		y = 100,
#		easing_points = [0.55, 0.055, 0.675, 0.19],
#		pivot = Anima.PIVOT.CENTER
#	},
#	60: {
#		opacity = 1,
#		scale = Vector2(0.475, 0.475),
#		y = 100,
#		easing_points = [0.55, 0.055, 0.675, 0.19]
#	},
#	100: {
#		scale = Vector2(1, 1),
#		y = 0
#	}
#
func add_frames(animation_data: Dictionary, full_keyframes_data: Dictionary) -> float:
	var last_duration := 0.0
	var is_first_frame = true
	var relative_properties: Array = ["x", "y", "z", "position", "position:x", "position:z", "position:y"]
	var pivot = full_keyframes_data.pivot if full_keyframes_data.has("pivot") else null

	if full_keyframes_data.has("relative"):
		relative_properties = full_keyframes_data.relative

	# Flattens the keyframe_data
	var keyframes_data = _flatten_keyframes_data(full_keyframes_data)
	var frame_keys: Array = keyframes_data.keys()
	frame_keys.sort_custom(self, "_sort_frame_index")

	animation_data.erase("animation")
	keyframes_data.erase("pivot")

	var previous_frame: Dictionary
	var previous_frame_key: float
	var wait_time: float = animation_data._wait_time if animation_data.has('_wait_time') else 0.0

	if pivot:
		animation_data.pivot = pivot

	for frame_key in frame_keys:
		if (not frame_key is int and not frame_key is float) or frame_key > 100:
			continue

		var keyframe_data: Dictionary = keyframes_data[frame_key]

		if previous_frame.size() > 0:
			wait_time += _calculate_frame_data(wait_time, animation_data, relative_properties, frame_key, keyframes_data[frame_key], previous_frame_key, previous_frame)
		else:
			#
			# For relative-only values we need to create a fake frame
			# used to set the from property to the expected value.
			for property_to_animate in keyframe_data.keys():
				if relative_properties.find(property_to_animate) < 0:
					continue

				var data = animation_data.duplicate()
				var to_value = keyframe_data[property_to_animate]

				data.property = property_to_animate
				data.relative = relative_properties.find(property_to_animate) >= 0
				data.duration = Anima.MINIMUM_DURATION
				data._wait_time = wait_time
				data.to = to_value
				data._ignore_for_backwards = true

				add_animation_data(data)

			wait_time += Anima.MINIMUM_DURATION

		previous_frame_key = frame_key
		previous_frame = keyframes_data[frame_key]

	return 0.0

func _flatten_keyframes_data(data: Dictionary) -> Dictionary:
	var result := {}

	for key in data:
		if not key is Array:
			result[key] = data[key]
			
			continue

		for percentage in key:
			result[percentage] = data[key]

	return result

func _sort_frame_index(a, b) -> bool:
	return int(a) < int(b)

func _calculate_frame_data(wait_time: float, animation_data: Dictionary, relative_properties: Array, current_frame_key: float, frame_data: Dictionary, previous_frame_key: float, previous_frame: Dictionary) -> float:
	var percentage = (current_frame_key - previous_frame_key) / 100.0
	var duration: float = animation_data.duration if animation_data.has('duration') else 0.0
	var easing = previous_frame.easing if previous_frame.has("easing") else null
	var pivot = previous_frame.pivot if previous_frame.has("pivot") else null
	var frame_duration = max(Anima.MINIMUM_DURATION, duration * percentage)

	previous_frame.erase("easing")
	previous_frame.erase("pivot")

	for property_to_animate in frame_data.keys():
		var data = animation_data.duplicate()

		if not previous_frame.has(property_to_animate):
			continue

		var from_value = previous_frame[property_to_animate]
		var to_value = frame_data[property_to_animate]
		var relative = relative_properties.find(property_to_animate) >= 0

		data.property = property_to_animate
		data.relative = relative
		data.duration = frame_duration
		data._wait_time = wait_time
		data.to = to_value
		data.easing = easing

		if not relative:
			data.from = from_value
		else:
			data.to -= from_value

#		printt(current_frame_key, percentage, frame_duration, data)
		add_animation_data(data)
		
#		var diff = frame_duration - last_duration
#		var is_last_frame = percentage == 1
#		var properties_to_animate: Array = keyframe_data.keys()
#
#		for property_to_animate in properties_to_animate:
#			var animation_data = data.duplicate()
#			var value = keyframes_data[frame_key][property_to_animate]
#			var is_relative = relative and POSITION_PROPERTIES.find(property_to_animate) >= 0
#
#			animation_data.property = property_to_animate
#			animation_data.relative = is_relative
#			animation_data.duration = diff
#			animation_data._wait_time = _wait_time
#			animation_data.to = value
#
##			# We need to restore the animation just before the node is animated
##			# but we also need to consider that a node can have multiple
##			# properties animated, so we need to restore it only before the first
##			# animation starts
##			for animation in _animation_data:
##				if animation.node == data.node:
##					is_first_frame = false
##
##					if animation.has('_is_last_frame'):
##						is_last_frame = false
##
##			if is_first_frame:
##				animation_data._is_first_frame = true
##
##			if is_last_frame:
##				animation_data._is_last_frame = true
#
##			for key in data:
##				if key == 'callback' and percentage < 1:
##					animation_data.erase(key)
##				elif keys_to_ignore.find(key) < 0:
##					animation_data[key] = data[key]
#
#			print(animation_data)
#			add_animation_data(animation_data)
#
#			last_duration = frame_duration
#

	return frame_duration

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

	data.invert()
	for animation in data:
		if animation.has("_ignore_for_backwards"):
			continue

		var animation_data = animation.duplicate(true)
		var duration: float = float(animation_data.duration) if animation_data.has('duration') else default_duration
		var wait_time: float = animation_data._wait_time
		var node = animation_data.node
		var new_wait_time: float = length - duration - wait_time
		var property = animation_data.property
		var is_relative = animation_data.has("relative") and animation_data.relative

		if not is_relative:
			var temp = animation_data.to

			animation_data.to = animation_data.from
			animation_data.from = temp

		animation_data._wait_time = max(Anima.MINIMUM_DURATION, new_wait_time)

		var old_on_completed = animation_data.on_completed if animation_data.has("on_completed") else null
		var erase_on_completed := true

		if animation_data.has("on_started"):
			animation_data.on_completed = animation_data.on_started
			animation_data.erase("on_started")

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
#
#		if animation_data.has('property') and animation_data.property == 'opacity':
#			node.remove_meta('_old_modulate')


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

func _on_tween_completed(node, _ignore) -> void:
	node.on_completed()

	_tween_completed += 1

	if _tween_completed >= _animation_data.size():
		stop_all()

		emit_signal("animation_completed")

func _on_tween_started(node, _ignore) -> void:
	node.on_started()

class AnimatedItem extends Node:
	var _node: Node
	var _property
	var _key
	var _subKey
	var _animation_data: Dictionary
	var _loop_strategy: int = Anima.LOOP.USE_EXISTING_RELATIVE_DATA
	var _is_backwards_animation: bool = false
	var _root_node: Node
	var _animation_callback: FuncRef
	var _visibility_strategy: int
	var _property_data: Dictionary

	func on_started() -> void:
		var visibility_strategy = _visibility_strategy

		if _node.has_meta("_visibility_strategy_reverted"):
			return

		_node.set_meta("_visibility_strategy_reverted", true)

		if _animation_data.has("visibility_strategy"):
			visibility_strategy = _animation_data.visibility_strategy

		var should_restore_visibility := false
		var should_restore_modulate := false

		if visibility_strategy == Anima.VISIBILITY.HIDDEN_ONLY:
			should_restore_visibility = true
		elif visibility_strategy == Anima.VISIBILITY.HIDDEN_AND_TRANSPARENT:
			should_restore_modulate = true
			should_restore_visibility = true
		elif visibility_strategy == Anima.VISIBILITY.TRANSPARENT_ONLY:
			should_restore_modulate = true

		if should_restore_modulate:
			var old_modulate

			if _node.has_meta('_old_modulate'):
				old_modulate = _node.get_meta('_old_modulate')
				old_modulate.a = 1.0

			if old_modulate:
				_node.modulate = old_modulate

		if should_restore_visibility:
			_node.show()

		var should_trigger_on_started: bool = _animation_data.has('_is_first_frame') and _animation_data._is_first_frame and _animation_data.has('on_started')
		if should_trigger_on_started:
			_execute_callback(_animation_data.on_started)

	func on_completed() -> void:
		if _loop_strategy == Anima.LOOP.RECALCULATE_RELATIVE_DATA:
			_property_data.clear()

		var should_trigger_on_completed = _animation_data.has('on_completed') and _animation_data.has('_is_last_frame')

		if should_trigger_on_completed:
			_execute_callback(_animation_data.on_completed)

	func set_animation_data(data: Dictionary, property_data: Dictionary, is_backwards_animation: bool, visibility_strategy) -> void:
		_animation_data = data
		_is_backwards_animation = is_backwards_animation
		_visibility_strategy = visibility_strategy

		_property = property_data.property_name
		_key = property_data.key if property_data.has("key") else null
		_subKey = property_data.subkey if property_data.has("subkey") else null

		_node = data.node
		_node.remove_meta("_visibility_strategy_reverted")

	func animate(elapsed: float) -> void:
		if _property_data.size() == 0:
			_property_data = AnimaTweenUtils.calculate_from_and_to(_animation_data, _is_backwards_animation)

		var from = _property_data.from
		var diff = _property_data.diff

		var value = from + (diff * elapsed)

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

	func animate_with_anima_easing(elapsed: float):
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

class AnimatedPropertyItem extends AnimatedItem:
	func apply_value(value) -> void:
		_node[_property] = value

class AnimatedPropertyWithKeyItem extends AnimatedItem:
	func apply_value(value) -> void:
		_node[_property][_key] = value

class AnimatedPropertyWithSubKeyItem extends AnimatedItem:
	func apply_value(value) -> void:
		_node[_property][_key][_subKey] = value

class AnimateObject extends AnimatedItem:
	func apply_value(value) -> void:
		_property[_key][_subKey] = value

class AnimateRect2 extends AnimatedItem:
	func animate(elapsed: float) -> void:
		if _property_data.size() == 0:
			_property_data = AnimaTweenUtils.calculate_from_and_to(_animation_data, _is_backwards_animation)

		apply_value(Rect2(
			_property_data.from.position + (_property_data.diff.position * elapsed),
			_property_data.from.size + (_property_data.diff.size * elapsed)
		))

	func apply_value(value: Rect2) -> void:
		_node[_property] = value
