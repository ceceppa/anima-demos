tool
extends "./_anima_node.gd"

func _init():
	register_node({
		category = 'Anima',
		name = 'AnimaNode',
		icon = 'res://addons/anima/icons/anima.svg',
		type = AnimaUI.NodeType.START,
		playable = false,
		closable = false
	})

func setup():
	add_output_slot("then", AnimaUI.PortType.ANIMATION)
	add_output_slot("with", AnimaUI.PortType.ANIMATION)

func is_shader_output() -> bool:
	return true

func input_connected(slot: int, from: Node, from_port: int) -> void:
	.input_connected(slot, from, from_port)
