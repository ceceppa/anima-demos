tool
extends Node

var _node: Node
var _property: String
var _key: String
var _subKey: String
var _animation_data: Dictionary
var _loop_strategy: int = Anima.LOOP.USE_EXISTING_RELATIVE_DATA
var _is_backwards_animation: bool = false
var _root_node: Node
var _animation_callback: FuncRef

func set_animation_data(data: Dictionary) -> void:
	_animation_data = data

func animate(value) -> void:
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
	print(elapsed)
	animate(elapsed)

func _cubic_bezier(p0: Vector2, p1: Vector2, p2: Vector2, p3: Vector2, t: float) -> float:
	var q0 = p0.linear_interpolate(p1, t)
	var q1 = p1.linear_interpolate(p2, t)
	var q2 = p2.linear_interpolate(p3, t)

	var r0 = q0.linear_interpolate(q1, t)
	var r1 = q1.linear_interpolate(q2, t)

	var s = r0.linear_interpolate(r1, t)

	return s.y
