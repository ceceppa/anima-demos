tool

class_name AnimaNode
extends Node

signal animation_started
signal animation_completed
signal loop_started
signal loop_completed

var _anima_tween := AnimaTween.new()

var _total_animation_length := 0.0
var _last_animation_duration := 0.0

var _timer := Timer.new()
var _loop_times := 0
var _loop_count := 0
var _should_loop := false
var _loop_strategy = Anima.LOOP.USE_EXISTING_RELATIVE_DATA
var _play_mode: int = AnimaTween.PLAY_MODE.NORMAL
var _default_duration = Anima.DEFAULT_DURATION
var _apply_visibility_strategy_on_play := true
var _play_speed := 1.0

var __do_nothing := 0.0
export (Dictionary) var __anima_visual_editor_data

func _ready():
	if _timer.get_parent() != self:
		_init_node(self)

func _exit_tree():
	if _timer:
		_timer.stop()

	_anima_tween.stop_all()

	_timer.queue_free()
	_anima_tween.queue_free()

func _init_node(node: Node):
	_timer.one_shot = true
	_timer.autostart = false
	_timer.connect("timeout", self, '_on_timer_timeout')

	_anima_tween.connect("tween_all_completed", self, '_on_all_tween_completed')

	add_child(_timer)
	add_child(_anima_tween)

	if node != self:
		node.add_child(self)

func generate_from_visual_data(node: Node, visual_data: Dictionary) -> void:
	var data = {
		node = node,
		duration = visual_data.duration,
		delay = visual_data.delay
	}

	var is_first := true

	for animation in visual_data.animations:
		if animation.type == AnimaUI.VISUAL_ANIMATION_TYPE.ANIMATION:
			data.animation = animation.animation.name

		if is_first:
			then(data)
		else:
			also(data)

		is_first = false

func then(data: Dictionary) -> float:
	data._wait_time = _total_animation_length

	_last_animation_duration = _setup_animation(data)

	var delay = data.delay if data.has('delay') else 0.0
	_total_animation_length += _last_animation_duration + delay

	return _last_animation_duration

func with(data: Dictionary) -> float:
	var start_time := 0.0
	var delay = data.delay if data.has('delay') else 0.0

	start_time = max(0, _total_animation_length - _last_animation_duration)

	if not data.has('duration'):
		if _last_animation_duration > 0:
			data.duration = _last_animation_duration
		else:
			data.duration = _default_duration

	if not data.has('_wait_time'):
		data._wait_time = start_time

	return _setup_animation(data)

func also(data: Dictionary, extra_keys_to_ignore := []) -> float:
	if _anima_tween.get_animations_count() == 0:
		printerr('.also can be only used in after a .then or .with!')

		return _last_animation_duration

	var animation_data: Array = _anima_tween.get_animation_data()
	var previous_data = animation_data[animation_data.size() - 1]

	var keys_to_ignore = [
		'_is_first_frame',
		'_is_last_frame',
		'_wait_time',
		'delay',
		'relative',
		'_grid_node'
	]

	if previous_data.has('_grid_node'):
		previous_data.grid = previous_data._grid_node

	for key in previous_data:
		if keys_to_ignore.find(key) >= 0 or extra_keys_to_ignore.find(key) >= 0:
			continue

		if not data.has(key):
			data[key] = previous_data[key]

	return with(data)

func group(group_data: Array, animation_data: Dictionary) -> void:
	var delay_index := 0

	_total_animation_length += animation_data.duration

	for index in group_data.size():
		var group_item: Dictionary = group_data[index]
		var data = animation_data.duplicate()

		data._wait_time = animation_data.items_delay * delay_index

		if group_item.has('node'):
			data.node = group_item.node
			delay_index += 1
		else:
			data.group = group_item.group
			delay_index += data.group.get_child_count()

		with(data)

	_total_animation_length += animation_data.items_delay * (delay_index - 1)

func wait(seconds: float) -> void:
	then({
		node = self,
		property = '__do_nothing',
		from = 0.0,
		to = 1.0,
		duration = seconds,
	})

func set_visibility_strategy(strategy: int, always_apply_on_play := true) -> void:
	_anima_tween.set_visibility_strategy(strategy)

	if always_apply_on_play:
		_apply_visibility_strategy_on_play = true

func clear() -> void:
	stop()

	_anima_tween.clear_animations()

	_total_animation_length = 0.0
	_last_animation_duration = 0.0
	set_visibility_strategy(Anima.VISIBILITY.IGNORE)

func play() -> void:
	_play(AnimaTween.PLAY_MODE.NORMAL)

func play_with_delay(delay: float) -> void:
	_play(AnimaTween.PLAY_MODE.NORMAL, delay)

func play_with_speed(speed: float) -> void:
	_play(AnimaTween.PLAY_MODE.NORMAL, 0.0, speed)

func play_backwards() -> void:
	_play(AnimaTween.PLAY_MODE.BACKWARDS)

func play_backwards_with_delay(delay: float) -> void:
	_play(AnimaTween.PLAY_MODE.BACKWARDS, delay)

func play_backwards_with_speed(speed: float) -> void:
	_play(AnimaTween.PLAY_MODE.BACKWARDS, 0.0, speed)

func _play(mode: int, delay: float = 0, speed := 1.0) -> void:
	_loop_times = 1
	_play_mode = mode
	_play_speed = speed

	if _apply_visibility_strategy_on_play and mode == AnimaTween.PLAY_MODE.NORMAL:
		set_visibility_strategy(_anima_tween._visibility_strategy)

	_timer.one_shot = true
	_timer.wait_time = max(0.00001, delay)
	_timer.start()

func stop() -> void:
	_timer.stop()
	_anima_tween.stop_all()

func loop(times: int = -1) -> void:
	_do_loop(times, AnimaTween.PLAY_MODE.NORMAL)

func loop_backwards(times: int = -1) -> void:
	_do_loop(times, AnimaTween.PLAY_MODE.BACKWARDS)

func loop_backwards_with_delay(delay: float, times: int = -1) -> void:
	_do_loop(times, AnimaTween.PLAY_MODE.NORMAL, delay)

func loop_with_delay(delay: float, times: int = -1) -> void:
	_do_loop(times, AnimaTween.PLAY_MODE.NORMAL, delay)

func loop_times_with_delay(times: float, delay: float) -> void:
	_do_loop(times, AnimaTween.PLAY_MODE.NORMAL, delay)

func _do_loop(times: int, mode: int, delay: float = Anima.MINIMUM_DURATION) -> void:
	_loop_times = times
	_should_loop = times == -1
	_play_mode = mode

	_timer.wait_time = max(Anima.MINIMUM_DURATION, delay)

	# Can't use _anima_tween.repeat
	# as the tween_all_completed is never called :(
	# But we need it to reset some stuff
	_do_play()

func get_length() -> float:
	return _total_animation_length

func _do_play() -> void:
	# Allows to reset the "relative" properties to the value of the 1st loop
	# before doing another loop
	_anima_tween.reset_data(_loop_strategy, _play_mode, _total_animation_length, _play_speed)

	_loop_count += 1

	_anima_tween.play()

	emit_signal("animation_started")
	emit_signal("loop_started", _loop_count)

func set_loop_strategy(strategy: int):
	_loop_strategy = strategy

#
# Returns the node that Anima will use when handling the animations
# done via visual editor
#
func get_source_node() -> Node:
	var parent = self.get_parent()

	if parent == null:
		return self

	return parent

func set_default_duration(duration: float) -> void:
	_default_duration = duration

func _setup_animation(data: Dictionary) -> float:
	if data.has('grid'):
		if not data.has('grid_size'):
			printerr('Please specify the grid size, or use `group` instead')

			return 0.0

		return _setup_grid_animation(data)
	elif data.has('group'):
		if not data.has('grid_size'):
			data.grid_size = Vector2(1, data.group.get_children().size())

		return _setup_grid_animation(data)
	elif not data.has('node'):
		 data.node = self.get_parent()

	return _setup_node_animation(data)

func _setup_node_animation(data: Dictionary) -> float:
	var node = data.node
	var delay = data.delay if data.has('delay') else 0.0
	var duration = data.duration if data.has('duration') else _default_duration

	data._wait_time = max(0.0, data._wait_time + delay)

	if data.has('property') and not data.has('animation'):
		data._is_first_frame = true
		data._is_last_frame = true

	if data.has('animation'):
		var script = Anima.get_animation_script(data.animation)

		if not script:
			printerr('animation not found: %s' % data.animation)

			return duration

		var callback: FuncRef = funcref(script, 'generate_animation')

		if script.has_method(data.animation):
			callback = funcref(script, data.animation)

		var real_duration = callback.call_func(_anima_tween, data)
		if real_duration is float:
			duration = real_duration
	else:
		_anima_tween.add_animation_data(data)

	return duration

func _setup_grid_animation(animation_data: Dictionary) -> float:
	var animation_type = Anima.GRID.SEQUENCE_TOP_LEFT
	
	if animation_data.has('animation_type'):
		animation_type = animation_data.animation_type

	if not animation_data.has('items_delay'):
		animation_data.items_delay = Anima.DEFAULT_ITEMS_DELAY

	if animation_data.has('grid'):
		animation_data._grid_node = animation_data.grid
	else:
		animation_data._grid_node = animation_data.group

	animation_data.erase('grid')
	animation_data.erase('group')

	var duration: float

	match animation_type:
		Anima.GRID.TOGETHER:
			duration = _generate_animation_all_together(animation_data)
		Anima.GRID.COLUMNS_EVEN:
			duration = _generate_animation_for_even_columns(animation_data)
		Anima.GRID.COLUMNS_ODD:
			duration = _generate_animation_for_odd_columns(animation_data)
		Anima.GRID.ROWS_ODD:
			duration = _generate_animation_for_odd_rows(animation_data)
		Anima.GRID.ROWS_EVEN:
			duration = _generate_animation_for_even_rows(animation_data)
		Anima.GRID.ODD:
			duration = _generate_animation_for_odd_items(animation_data)
		Anima.GRID.EVEN:
			duration = _generate_animation_for_even_items(animation_data)
		_:
			duration = _generate_animation_sequence(animation_data, animation_type)

	return animation_data.duration

func _get_children(animation_data: Dictionary, shuffle := false) -> Array:
	var grid_node = animation_data._grid_node
	var grid_size = animation_data.grid_size

	var nodes := []
	var rows: int = grid_size.x
	var columns: int = grid_size.y

	var row_items := []
	var index := 0

	var children: Array = grid_node.get_children()
	
	if shuffle:
		randomize()

		children.shuffle()

	for child in children:
		# Skip current node :)
		if '__do_nothing' in child:
			continue
		elif animation_data.has('skip_hidden') and not child.is_visible():
			continue

		row_items.push_back(child)

		index += 1
		if index >= columns:
			nodes.push_back(row_items)
			row_items = []
			index = 0

	if row_items.size() > 0:
		nodes.push_back(row_items)

	return nodes

func _generate_animation_sequence(animation_data: Dictionary, start_from: int) -> float:
	var nodes := []
	var children := _get_children(animation_data, start_from == Anima.GRID.RANDOM)
	var is_grid: bool = animation_data.grid_size.x > 1
	var grid_size: Vector2 = animation_data.grid_size
	var from_x: int
	var from_y: int

	from_y = grid_size.y / 2
	from_x = grid_size.x / 2

	if start_from == Anima.GRID.FROM_POINT and not animation_data.has('point'):
		start_from = Anima.GRID.FROM_CENTER

	for row_index in children.size():
		var row: Array = children[row_index]
		var from_index = 0

		if start_from == Anima.GRID.SEQUENCE_BOTTOM_RIGHT:
			from_index = row.size() - 1
		elif start_from == Anima.GRID.FROM_CENTER:
			from_index = (row.size() - 1) / 2
		elif start_from == Anima.GRID.FROM_POINT:
			if is_grid:
				from_y = animation_data.point.y
				from_x = animation_data.point.x
			else:
				from_index = animation_data.point.x

		for index in row.size():
			var current_index = index
			var distance: int = abs(from_index - current_index)
			
			if is_grid:
				var distance_x = index - from_y
				var distance_y = row_index - from_x

				distance = sqrt(distance_x * distance_x + distance_y * distance_y)

			var node = row[index]

			nodes.push_back({ node = node, delay_index = distance })

	return _create_grid_animation_with(nodes, animation_data)

func _generate_animation_sequence_bottom_right(animation_data: Dictionary) -> float:
	var nodes := []

	for row in _get_children(animation_data):
		for child in row:
			nodes.push_front(child)

	return _create_grid_animation_with(nodes, animation_data)

func _generate_animation_all_together(animation_data: Dictionary) -> float:
	var nodes := []
	for row in _get_children(animation_data):
		for child in row:
			nodes.push_back(child)

	animation_data.items_delay = 0

	return _create_grid_animation_with(nodes, animation_data)

func _generate_animation_for_even_columns(animation_data: Dictionary) -> float:
	var columns := []
	var rows := []
	var grid_size = animation_data.grid_size

	for row in grid_size.x:
		rows.push_back(row)

	for column in grid_size.y:
		if column % 2 == 0:
			columns.push_back(column)

	return _generate_animation_for(rows, columns, animation_data)

func _generate_animation_for_odd_columns(animation_data: Dictionary) -> float:
	var columns := []
	var rows := []
	var grid_size = animation_data.grid_size

	for row in grid_size.x:
		rows.push_back(row)

	for column in grid_size.y:
		if column % 2 != 0:
			columns.push_back(column)

	return _generate_animation_for(rows, columns, animation_data)

func _generate_animation_for_odd_rows(animation_data: Dictionary) -> float:
	var columns := []
	var rows := []
	var grid_size = animation_data.grid_size

	for row in grid_size.x:
		if row % 2 != 0:
			rows.push_back(row)

	for column in grid_size.y:
		columns.push_back(column)

	return _generate_animation_for(rows, columns, animation_data)

func _generate_animation_for_even_rows(animation_data: Dictionary) -> float:
	var columns := []
	var rows := []
	var grid_size = animation_data.grid_size

	for row in grid_size.x:
		if row % 2 == 0:
			rows.push_back(row)

	for column in grid_size.y:
		columns.push_back(column)

	return _generate_animation_for(rows, columns, animation_data)

func _generate_animation_for(rows: Array, columns: Array, animation_data: Dictionary) -> float:
	var nodes := []
	var children = _get_children(animation_data)

	for row in rows:
		for column in columns:
			nodes.push_back(children[row][column])

	return _create_grid_animation_with(nodes, animation_data)

func _generate_animation_for_odd_items(animation_data: Dictionary) -> float:
	var nodes := []
	var children = _get_children(animation_data)

	for row_index in children.size():
		for column_index in children[row_index].size():
			if (column_index + row_index)  % 2 == 0:
				var child = children[row_index][column_index]

				nodes.push_back(child)

	return _create_grid_animation_with(nodes, animation_data)

func _generate_animation_for_even_items(animation_data: Dictionary) -> float:
	var nodes := []
	var children = _get_children(animation_data)

	for row_index in children.size():
		for column_index in children[row_index].size():
			if (column_index + row_index)  % 2 != 0:
				var child = children[row_index][column_index]

				nodes.push_back(child)

	return _create_grid_animation_with(nodes, animation_data)

func _create_grid_animation_with(nodes: Array, animation_data: Dictionary) -> float:
	for index in nodes.size():
		var node = nodes[index]
		var delay_index = index

		if node is Dictionary:
			delay_index = node.delay_index
			node = node.node

		var data = animation_data.duplicate()

		data.node = node
		if not data.has('delay'):
			data.delay = 0

		data.delay += data.items_delay * delay_index

		with(data)

	return animation_data.duration + (animation_data.items_delay * nodes.size())

func _on_timer_timeout() -> void:
	_do_play()

	_loop_times -= 1

	if _loop_times > 0 or _should_loop:
		_do_play()

func _on_all_tween_completed() -> void:
	emit_signal("animation_completed")
	emit_signal("loop_completed", _loop_count)

	if _should_loop:
		_timer.start()
