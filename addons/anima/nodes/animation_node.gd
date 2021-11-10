tool
extends "./_base_node.gd"

const ANIMATION_CONTROL = preload("res://addons/anima/nodes/AnimaAnimationControl.tscn")

var _animation_control
var _animation_control_data: Dictionary = {}

func _init():
	register_node({
		category = 'Anima',
		id = 'Animation',
		name = 'Animation',
#		icon = 'res://addons/anima/icons/node.svg',
		type = AnimaUI.NODE_TYPE.ANIMATION,
		min_size = Vector2(350, 0)
	})

func setup():
	add_slot({
		input = {
			label = "animate",
			type = AnimaUI.PORT_TYPE.ANIMATION,
		},
		output = {
			label = "then",
			type = AnimaUI.PORT_TYPE.ANIMATION,
			tooltip = tr("Animates the next node when this one has been completed")
		}
	})

	add_slot({
		output = {
			label = "with",
			type = AnimaUI.PORT_TYPE.ANIMATION,
			tooltip = tr("Animates the next node at the same time of this one")
		}
	})

	add_slot({
		output = {
			label = "also",
			type = AnimaUI.PORT_TYPE.ANIMATION,
			tooltip = tr("This is used to animate a different property for this node")
		}
	})

	add_slot({
		output = {
			label = "on_started",
			type = AnimaUI.PORT_TYPE.ACTION,
			tooltip = tr("Execute an action when the animation starts")
		}
	})
	add_slot({
		output = {
			label = "on_completed",
			type = AnimaUI.PORT_TYPE.ACTION,
			tooltip = tr("Execute an action when the animation completes")
		}
	})

	_animation_control = ANIMATION_CONTROL.instance()
	_animation_control.populate_animatable_properties_list(_node_to_animate)
	_animation_control.connect("animation_updated", self, "_on_animation_selected")
	_animation_control.connect("content_size_changed", self, "_on_animation_control_content_size_changed")

	add_custom_row(_animation_control)

func _after_render() -> void:
	_animation_control.restore_data(_animation_control_data)
	
	._after_render()

func set_node_to_animate(node: Node) -> void:
	AnimaUI.debug(self, 'set node to animate', node)

	_node_to_animate = node

	set_title(_node_to_animate.name)
	set_icon(AnimaUI.get_node_icon(node))

func get_node_to_animate() -> Node:
	return _node_to_animate

func restore_data(data: Dictionary) -> void:
	_animation_control_data = data

func get_data() -> Dictionary:
	return _animation_control.get_animations_data()

func input_connected(slot: int, from: Node, from_port: int) -> void:
	.input_connected(slot, from, from_port)

func _on_animation_selected() -> void:
	emit_signal("node_updated")

func _on_animation_control_content_size_changed(new_size: float) -> void:
	var min_height := 0.0

	for child in get_children():
		if child is Control:
			min_height += child.rect_size.y

	var to := min_height + new_size

	_animate_height(to)

func _animate_height(to: float) -> void:
	var anima: AnimaNode = Anima.begin(self, 'resizeMe')
	anima.set_single_shot(true)

	anima.then({ property = "rect_size:y", to = to, duration = 0.3, easing = Anima.EASING.EASE_OUT_BACK })

	anima.play()

func _on_show_content() -> void:
	_animation_control.show()

	_animate_height(_animation_control.rect_size.y)

func _on_hide_content() -> void:
	_animation_control.hide()
	
	_animate_height(0)
