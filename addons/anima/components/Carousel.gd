tool
extends VBoxContainer
class_name AnimaCarousel

signal carousel_size_changed(new_size)
signal carousel_height_changed(final_height)
signal index_changed(new_index)

onready var _container: HBoxContainer = find_node('Container')
onready var _controls: HBoxContainer = find_node('Controls')

export (int) var index setget set_index
export (float) var duration = 0.3
export (Anima.EASING) var scroll_easing = Anima.EASING.LINEAR
export (Anima.EASING) var height_easing = Anima.EASING.LINEAR

var _heights: Array

func _ready():
	for index in _controls.get_child_count():
		var child: Node = _controls.get_child(index)

		if child is Button:
			child.connect("pressed", self, "_on_control_pressed", [index])
			
	_update_size()

func _update_size():
	_container.rect_min_size.x = rect_size.x * _container.get_child_count()

	for child in _container.get_children():
		var node: Control = child

		node.size_flags_horizontal = SIZE_EXPAND_FILL
		node.size_flags_vertical = 0

		_heights.push_back(node.rect_size.y)

	set_index(index)

func _maybe_get_container() -> void:
	_container = find_node('Container')

func get_active_index() -> int:
	return index

func set_index(new_index: int) -> void:
	if not is_inside_tree():
		return

	var count: int = max(0, _container.get_child_count() - 1)
	index = clamp(new_index, 0, count)

	var x = rect_size.x * index
	var wrapper_height = _heights[index]
	var height = _controls.rect_size.y + wrapper_height

	var anima: AnimaNode = Anima.begin(self)
	anima.set_single_shot(true)

	anima.then({ property = "size:y", to = height, easing = height_easing, duration = duration })
	anima.also({ node = _container, property = "position:x", to = -x, easing = scroll_easing })
	anima.also({ node = $Wrapper, property = "size:y", to = wrapper_height, easing = height_easing })
	anima.play()

	emit_signal("carousel_height_changed", height)
	emit_signal("index_changed", new_index)

func _on_Container_item_rect_changed() -> void:
	emit_signal("carousel_size_changed", rect_size)

func _on_control_pressed(index: int) -> void:
	set_index(index)
