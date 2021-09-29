tool
extends "./_base_node.gd"

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
	add_output_slot("manual", ".play()", AnimaUI.PortType.ANIMATION)
	add_divider()
	add_label('On Event')
	add_output_slot("enter tree", "", AnimaUI.PortType.ANIMATION)
	add_output_slot("exit tree", "", AnimaUI.PortType.ANIMATION)
	add_spacer()
	add_output_slot("visible", "", AnimaUI.PortType.ANIMATION)
	add_output_slot("hidden", "", AnimaUI.PortType.ANIMATION)
	add_spacer()
	add_output_slot("focus entered", "", AnimaUI.PortType.ANIMATION)
	add_output_slot("focus exited", "", AnimaUI.PortType.ANIMATION)

func is_shader_output() -> bool:
	return true

func input_connected(slot: int, from: Node, from_port: int) -> void:
	.input_connected(slot, from, from_port)
