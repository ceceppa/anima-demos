tool
extends "./_base_node.gd"

const ANIMATION_NAME_ROW = preload('res://addons/anima/ui/animation_name_row.tscn')

var _add_button: Button
var _animations := ['default']

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
	_init_add_button()

	for index in _animations.size():
		var name = _animations[index]

		add_custom_output_slot(_create_animation_row(name, index > 0), name, AnimaUI.PortType.ANIMATION)

	add_custom_row(_add_button)
	add_divider()
	add_label('On Event')
	add_output_slot("enter tree", "Automatically plays the animation when the node is added to the scene", AnimaUI.PortType.EVENT)
	add_output_slot("exit tree", "Automatically plays the animation when the node is removed from the scene", AnimaUI.PortType.EVENT)
	add_spacer()
	add_output_slot("visible", "Automatically plays the anination when the node is made visible", AnimaUI.PortType.EVENT)
	add_output_slot("hidden", "Automatically plays the anination when the node is hidden", AnimaUI.PortType.EVENT)
	add_spacer()
	add_output_slot("focus entered", "Automatically plays the anination when the node receives the focus", AnimaUI.PortType.EVENT)
	add_output_slot("focus exited", "Automatically plays the anination when the node loses the focus", AnimaUI.PortType.EVENT)

func is_shader_output() -> bool:
	return true

func input_connected(slot: int, from: Node, from_port: int) -> void:
	.input_connected(slot, from, from_port)

func _create_animation_row(default_name: String, can_be_deleted := true) -> Node:
	var row = ANIMATION_NAME_ROW.instance()

	row.set_default_name(default_name)

	if not can_be_deleted:
		row.disable_delete_button()
		row.set_tooltip("This is the default animation that will be played when using any .play*() functions without specifying the animation name")

	return row

func _init_add_button():
	_add_button = Button.new()
	_add_button.text = "Add new animation"

	_add_button.connect("pressed", self, "_on_add_new_animation_pressed")
	_add_button.connect("tree_exited", self, "_trigger_rerender")

func _on_add_new_animation_pressed() -> void:
	var name = "New animation " + str(_animations.size())
	var _add_button_index = _add_button.get_position_in_parent()
	var previous = get_child(_add_button_index - 1)
	var node = _create_animation_row(name)

	add_child_below_node(previous, node)

	_node_body_data.insert(_animations.size(), {type = BodyDataType.OUTPUT_SLOT, node = node, data = [name, '', true, AnimaUI.PortType.ANIMATION]})

	_animations.push_back(name)

	_setup_slots()
