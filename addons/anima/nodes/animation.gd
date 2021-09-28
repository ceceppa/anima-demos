tool
extends "./_anima_node.gd"

var _node_to_animate: Node

func _init():
	register_node({
		category = 'Anima',
		name = 'Animation',
		icon = 'res://addons/anima/icons/node.svg',
		type = AnimaUI.NodeType.ANIMATION,
		closable = false
	})

func setup():
	add_input_slot("", AnimaUI.PortType.ANIMATION)
	add_output_slot("then", AnimaUI.PortType.ANIMATION)
	add_output_slot("with", AnimaUI.PortType.ANIMATION)
	add_row_animation_control()

func set_node_to_animate(node: Node) -> void:
	_node_to_animate = node
	
	set_title(_node_to_animate.name)

func is_shader_output() -> bool:
	return true

func input_connected(slot: int, from: Node, from_port: int) -> void:
	.input_connected(slot, from, from_port)
