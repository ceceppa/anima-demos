tool
extends "./_base_node.gd"

func _init():
	register_node({
		category = 'Anima',
		id = 'AnimaNode',
		name = 'AnimaNode',
		icon = 'res://addons/anima/icons/anima.svg',
		type = AnimaUI.NodeType.START,
		playable = false,
		closable = false
	})

func setup():
	add_output_slot("manual", "Use .play* function to run the animation manually", AnimaUI.PortType.ANIMATION)
	add_divider()
	add_label('On Event')
	add_output_slot("enter tree", "Automatically plays the animation when the node is added to the scene", AnimaUI.PortType.ANIMATION)
	add_output_slot("exit tree", "Automatically plays the animation when the node is removed from the scene", AnimaUI.PortType.ANIMATION)
	add_spacer()
	add_output_slot("visible", "Automatically plays the anination when the node is made visible", AnimaUI.PortType.ANIMATION)
	add_output_slot("hidden", "Automatically plays the anination when the node is hidden", AnimaUI.PortType.ANIMATION)
	add_spacer()
	add_output_slot("focus entered", "Automatically plays the anination when the node receives the focus", AnimaUI.PortType.ANIMATION)
	add_output_slot("focus exited", "Automatically plays the anination when the node loses the focus", AnimaUI.PortType.ANIMATION)

func is_shader_output() -> bool:
	return true

func input_connected(slot: int, from: Node, from_port: int) -> void:
	.input_connected(slot, from, from_port)
