tool
extends "./_base_node.gd"

var _node_to_animate: Node
var _animation_control

func _init():
	register_node({
		category = 'Anima',
		id = 'Animation',
		name = 'Animation',
#		icon = 'res://addons/anima/icons/node.svg',
		type = AnimaUI.NodeType.ANIMATION,
		min_size = Vector2(350, 150)
	})

func setup():
	add_slot({
		input = {
			label = "",
			type = AnimaUI.PortType.ANIMATION
		},
		output = {
			label = "then",
			type = AnimaUI.PortType.ANIMATION
		}
	})

	add_slot({
		output = {
			label = "with",
			type = AnimaUI.PortType.ANIMATION
		}
	})


	_animation_control = ANIMATION_CONTROL.instance()
	_animation_control.populate_animatable_properties_list(_node_to_animate)
	add_custom_row(_animation_control)

func set_node_to_animate(node: Node) -> void:
	print_debug('set node to animate', node)

	_node_to_animate = node

	set_title(_node_to_animate.name)
	set_icon(AnimaUI.get_node_icon(node))

func get_node_to_animate() -> Node:
	return _node_to_animate

func is_shader_output() -> bool:
	return true

func input_connected(slot: int, from: Node, from_port: int) -> void:
	.input_connected(slot, from, from_port)
