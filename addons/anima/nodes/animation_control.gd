tool
extends "./_base_node.gd"

var _node_to_animate: Node

func _init():
	register_node({
		category = 'Anima',
		id = 'Animation',
		name = 'Animation',
#		icon = 'res://addons/anima/icons/node.svg',
		type = AnimaUI.NodeType.ANIMATION,
		closable = false
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


	add_custom_row(ANIMATION_CONTROL.instance())

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
