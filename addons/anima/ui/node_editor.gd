tool
extends GraphEdit

const ANIMA_START_NODE = preload("res://addons/anima/nodes/start.gd")
var shader_output_node

signal node_connected
signal node_updated
signal generate_full_shader

func _init():
	self.connect('connection_request', self, '_on_connection_request')
	self.connect('disconnection_request', self, '_on_disconnection_request')

	print_debug("init")
	shader_output_node = ANIMA_START_NODE.new()

	# TODO: Add test
	shader_output_node.set_offset(Vector2(get_rect().size.x - 300, 20))
	shader_output_node.connect('generate_full_shader', self, '_on_generate_full_shader')
	add_child(shader_output_node)

	set_right_disconnects(true)

func get_shader_output_node():
	return shader_output_node

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

func add_node(fullQualifiedNodeName: String, add_node: bool = true) -> GraphNode:
	var node = find_node(fullQualifiedNodeName)

	if add_node:
		add_child(node)
		node.render()

	return node

func _on_disconnection_request(from: String, from_slot: int, to: String, to_slot: int):
	print_debug(from, from_slot, to, to_slot)
	pass

func _on_node_updated():
	emit_signal('node_updated')

func _on_generate_full_shader():
	emit_signal('generate_full_shader', shader_output_node)
