tool
extends GraphEdit

const ANIMA_START_NODE = preload("res://addons/anima/nodes/start.gd")
const ANIMA_ANIMATION_NODE = preload("res://addons/anima/nodes/animation.gd")
var _anima_start_node

signal node_connected
signal node_updated
signal show_nodes_list(position)
signal hide_nodes_list

func _init():
	self.connect('connection_request', self, '_on_connection_request')
	self.connect('disconnection_request', self, '_on_disconnection_request')

	_anima_start_node = ANIMA_START_NODE.new()

	# TODO: Add test
	_anima_start_node.set_offset(Vector2(get_rect().size.x - 300, 20))
	add_child(_anima_start_node)

	set_right_disconnects(true)

func get_shader_output_node():
	return _anima_start_node

func _on_connection_request(from_node: String, from_slot: int, to_node: String, to_slot: int) -> bool:
	if from_node == to_node:
		return false

	for connection in get_connection_list():
			if connection["to"] == to_node and connection["to_port"] == to_slot:
				disconnect_node(connection["from"], connection["from_port"], connection["to"], connection["to_port"])
				break

	connect_node(from_node, from_slot, to_node, to_slot)

	emit_signal("node_connected", get_connections())

	return true

func get_connections():
	var connections := [];
	for connection in get_connection_list():
		connections.push_back({
			'from': get_node(connection.from),
			'to': get_node(connection.to),
			'from_port': connection.from_port,
			'to_port': connection.to_port
		})

	return connections

func add_node(node_to_animate: Node, add_node: bool = true) -> GraphNode:
	var node = ANIMA_ANIMATION_NODE.new()

	node.set_node_to_animate(node_to_animate)

	if add_node:
		add_child(node)

	return node

func _on_disconnection_request(from: String, from_slot: int, to: String, to_slot: int):
	print_debug(from, from_slot, to, to_slot)
	pass

func _on_node_updated():
	emit_signal('node_updated')

func _on_GraphEdit_gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_RIGHT:
			emit_signal("show_nodes_list", event.global_position)
		else:
			emit_signal("hide_nodes_list")
